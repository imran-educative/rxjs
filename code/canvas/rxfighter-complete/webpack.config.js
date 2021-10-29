'use strict';

process.env.UV_THREADPOOL_SIZE = 100;

let path = require('path');
let webpack = require('webpack');
let execSync = require('child_process').execSync;

let loaders = [
  { test: /\.ts$/, loader: 'ts-loader' }
];

module.exports = {
  devtool: 'inline-source-map',
  entry: {
    app: './index.ts'
  },
  output: {
    filename: 'bundle.js'
  },
  module: {
    loaders: loaders
  },
  resolve: {
    extensions: ['.webpack.js', '.web.js', '.ts', '.js']
  }
};
