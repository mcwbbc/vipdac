#!/usr/bin/env ruby

  # builds the monitrc file for the nodes, so we launch the proper number of workers

  require 'rubygems'
  require 'net/http'
  require 'uri'
  require 'yaml'
  require 'right_aws'
  require 'right_http_connection'
  require 'zip/zip'
  require 'zip/zipfilesystem'
  require 'fileutils'
  require 'logger'

  # load order is important
  require '../app/models/constants'
  require '../app/models/utilities'

  require '../app/models/aws'
  require '../app/models/aws_parameters'
  require '../app/models/monitrc'

  Monitrc.run
