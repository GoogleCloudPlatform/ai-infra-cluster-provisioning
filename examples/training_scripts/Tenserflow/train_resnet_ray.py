# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Training script for ResNet on ImageNet.

IMPORTANT: Do not OSS this sample without removing references to the ImageNet
filepatterns below!
"""
import json
import os
from typing import Any, Dict, Tuple

from absl import app
from absl import flags
from absl import logging

import ray
from ray import train
import tensorflow as tf
from tensorflow.keras import callbacks
from tensorflow.keras.applications import resnet50

FLAGS = flags.FLAGS

_PER_REPLICA_BATCH_SIZE = flags.DEFINE_integer(
    'per_replica_batch_size', 512, 'Batch size per GPU for training examples.')

_NUM_TRAIN_EPOCHS = flags.DEFINE_integer('num_train_epochs', 10,
                                         'Number of training epochs to run.')

# Working on creating a public GSC Bucket to host this data.
# Once the public GCS bucket is available, this will be modified to point that.
_TRAINING_FILEPATTERN = flags.DEFINE_string(
    'training_filepattern',
    'gs://supercomputer-dev-us-east1/imagenet/train/train-000*',
    'Filepattern for TFRecords with ImageNet data for training.')

_VALIDATION_FILEPATTERN = flags.DEFINE_string(
    'validation_filepattern',
    'gs://supercomputer-dev-us-east1/imagenet/validation/validation-000*',
    'Filepattern for TFRecords with ImageNet data for validation.')


def _setup_tensorflow():
  os.environ['NCCL_DEBUG'] = 'WARN'
  os.environ['TF_GPU_THREAD_MODE'] = 'gpu_private'

  tf.keras.mixed_precision.set_global_policy('mixed_float16')
  gpus = tf.config.list_physical_devices('GPU')
  if not gpus:
    raise RuntimeError('No GPUs detected.')
  for gpu in gpus:
    tf.config.experimental.set_memory_growth(gpu, True)


@tf.function()
def _parse_example(serialized_record: str) -> Tuple[tf.Tensor, tf.Tensor]:
  """Parses a serialized TFExample for ImageNet.

  Args:
    serialized_record: Serialized TFExample.

  Returns:
    The image and label as tensors.
  """
  feature_map = {
      'image/encoded':
          tf.io.FixedLenFeature([], dtype=tf.string, default_value=''),
      'image/class/label':
          tf.io.FixedLenFeature([], dtype=tf.int64, default_value=-1),
      'image/class/text':
          tf.io.FixedLenFeature([], dtype=tf.string, default_value=''),
  }

  features = tf.io.parse_single_example(
      serialized=serialized_record, features=feature_map)
  label = tf.cast(features['image/class/label'], tf.int32) - 1
  label = tf.one_hot(label, depth=1000)
  image = tf.image.decode_jpeg(features['image/encoded'], channels=3)
  image = tf.image.resize_with_crop_or_pad(image, 224, 224)
  return image, label


def _get_train_eval_datasets(
    global_batch_size: int, training_filepattern: str,
    validation_filepattern: str) -> Tuple[tf.data.Dataset, tf.data.Dataset]:
  """Returns training and eval datasets.

  Args:
    global_batch_size: Global batch size for training.
    training_filepattern: Filepattern for training data.
    validation_filepattern: Filepattern for validation data.

  Returns:
    tf.data.Datasets representing training and validation datasets.
  """
  train_files = tf.data.TFRecordDataset(
      tf.data.Dataset.list_files(training_filepattern, shuffle=False))
  validation_files = tf.data.TFRecordDataset(
      tf.data.Dataset.list_files(validation_filepattern, shuffle=False))

  train_dataset = train_files.map(_parse_example).batch(
      global_batch_size, drop_remainder=True).cache()

  eval_dataset = validation_files.map(_parse_example).batch(
      global_batch_size, drop_remainder=True).cache()

  return train_dataset, eval_dataset


def _build_model():
  model = resnet50.ResNet50(include_top=True, weights=None)
  return model


def _train_and_eval(strategy: tf.distribute.Strategy,
                    per_replica_batch_size: int, num_train_epochs: int,
                    training_filepattern: str,
                    validation_filepattern: str) ->...:
  """Runs a train/eval loop on all GPUs found on the VM.

  Args:
    strategy: The TF distributed strategy to use.
    per_replica_batch_size: Per GPU batch size.
    num_train_epochs: Number of epochs to run the training loop.
    training_filepattern: Filepattern for training data.
    validation_filepattern: Filepattern for validation data.

  Returns:
    Keras training history object.
  """
  global_batch_size = per_replica_batch_size * strategy.num_replicas_in_sync
  logging.info('Num replicas in sync: %d', strategy.num_replicas_in_sync)
  logging.info('Using per-replica batch size %d with global batch size %d',
               per_replica_batch_size, global_batch_size)

  train_dataset, eval_dataset = _get_train_eval_datasets(
      global_batch_size=global_batch_size,
      training_filepattern=training_filepattern,
      validation_filepattern=validation_filepattern)

  with strategy.scope():
    model = _build_model()
    model.compile(
        optimizer='rmsprop',
        loss='categorical_crossentropy',
        metrics=['accuracy'])

  cb = [
      callbacks.TensorBoard(
          log_dir='/tmp/tensorboard', histogram_freq=1, update_freq='epoch'),
  ]
  history = model.fit(
      train_dataset,
      validation_data=eval_dataset,
      epochs=num_train_epochs,
      callbacks=cb)

  return history.history


def training_main(config: Dict[str, Any]) ->...:
  """Runs the training using the configuration passed in.

  Args:
    config: A dictionary with parameters for training the ResNet model.

  Returns:
    Keras training history object.
  """
  _setup_tensorflow()
  # Need to initialize MultiWorkerMirroredStrategy before any other TF Op.
  strategy = tf.distribute.MultiWorkerMirroredStrategy()

  tf_config = json.loads(os.environ['TF_CONFIG'])
  logging.info('Using TF_CONFIG: %s', tf_config)
  print('Using TF_CONFIG: ', tf_config)
  num_workers = len(tf_config['cluster']['worker'])
  num_gpus = len(tf.config.list_logical_devices('GPU'))
  logging.info(
      'Training using MultiWorkerMirroredStrategy. '
      'Num workers: %d, num GPUs: %d', num_workers, num_gpus)

  return _train_and_eval(strategy, config['per_replica_batch_size'],
                         config['num_train_epochs'],
                         config['training_filepattern'],
                         config['validation_filepattern'])


def main(_):
  logging.get_absl_handler().use_absl_log_file('tf_train_resnet', '/tmp')
  logging.info('Training Model: ResNet')

  ray.init(address='auto')
  trainer = train.Trainer(
      backend='tensorflow',
      num_workers=2,
      use_gpu=True,
      resources_per_worker={'GPU': 1})
  trainer.start()
  results = trainer.run(
      training_main, {
          'per_replica_batch_size': _PER_REPLICA_BATCH_SIZE.value,
          'num_train_epochs': _NUM_TRAIN_EPOCHS.value,
          'training_filepattern': _TRAINING_FILEPATTERN.value,
          'validation_filepattern': _VALIDATION_FILEPATTERN.value,
      })
  print(results)
  trainer.shutdown()

  return 0


if __name__ == '__main__':
  app.run(main)