const { webpackConfig, merge } = require('shakapacker')
const { VueLoaderPlugin } = require('vue-loader')
const webpack = require('webpack')
const dotenv = require('dotenv')
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

console.log("********************THIS IS WEBPACK CONFIG")

dotenv.config();

module.exports = merge({
  mode: process.env.RAILS_ENV,
  module: {
    rules: [
      {
        test: /\.vue$/,
        loader: 'vue-loader'
      },
      {
        test: /\.css$/i,
        use: ['css-loader', 'style-loader', 'sass-loader'],
      }
    ]
  },
  plugins: [
    new VueLoaderPlugin(),
    new webpack.DefinePlugin({
      'process.env': JSON.stringify(process.env)
   }),
   new MiniCssExtractPlugin({
    ignoreOrder: true
  }),
  ],
  resolve: {
    extensions: ['.ts', '.tsx', '.vue', '.css'],
    fallback: {
      "child_process": false,
      "fs": false,
      "http": false
    },
    alias: {
      vue: 'vue/dist/vue.esm'
    }
  }
}, webpackConfig)