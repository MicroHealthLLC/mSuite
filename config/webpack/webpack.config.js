const { webpackConfig, merge } = require('shakapacker')
const { VueLoaderPlugin } = require('vue-loader')
const webpack = require('webpack')
const dotenv = require('dotenv')
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const FilterWarningsPlugin = require("webpack-filter-warnings-plugin");

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
        use: ['style-loader', 'css-loader', 'sass-loader'],
      }
    ]
  },
  plugins: [
    new VueLoaderPlugin(),
    new webpack.DefinePlugin({
      RAILS_ENV: JSON.stringify(process.env.RAILS_ENV),
      WEBPACK_ENV: JSON.stringify(process.env.WEBPACK_ENV),
      BROWSER_SUPPORTS_HTML5: true,
      NODE_ENV: JSON.stringify(process.env.RAILS_ENV)
   }),
   new MiniCssExtractPlugin({
    filename: "[name].[chunkhash:5].css",
    chunkFilename: "[name].chunk.[chunkhash:5].css",
    ignoreOrder: true
    }),
    new FilterWarningsPlugin({
      exclude:
        /mini-css-extract-plugin[^]*Conflicting order. Following module has been added:/,
    })
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