#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'

# Gopher server
module MrGopher

  FieldSep = "\t"
  LineSep = "\r\n"
  ResponseEnd = '.'

  module Server

    def default_host=(host); @default_host = host; end
    def default_port=(port); @default_port = port; end
    def doc_store=(doc_store); @doc_store = doc_store; end

    def receive_data(data)
      send_data(render_doc(@doc_store.get(data.chomp)))
      close_connection_after_writing
    end

    def render_doc(doc)
      if doc.kind_of?(Array)
        doc.map { |d| render_menu_item(d) }.join + ResponseEnd
      else
        doc
      end
    end

    def render_menu_item(menu_item)
      host = menu_item[:host] || @default_host

      [
        menu_item[:type] || 0,
        menu_item[:display] || menu_item[:selector] || host, FieldSep,
        menu_item[:selector], FieldSep,
        host, FieldSep,
        menu_item[:port] || @default_port, LineSep
      ].join
    end

  end

  class DocStore

    def root; [ MrGopher.info('default') ]; end

    def dispatch(selector); end

    def get(selector); dispatch(selector) || root; end

  end

  module_function

  def text(selector, options={}); options.merge(:selector => selector); end

  def menu(selector, options={})
    options.merge(:type => 1, :selector => selector)
  end

  def info(info, options={}); options.merge(:type => 'i', :display => info); end

end

class MyDocStore < MrGopher::DocStore

  def root
    [
    MrGopher.info('hello'),
    MrGopher.text('doc1'),
    MrGopher.text('doc2'),
    MrGopher.menu('dir1'),
    MrGopher.info('Other Gopher servers'),
    MrGopher.menu(nil, :host => 'sdf.org'),
    ]
  end

  def dispatch(selector)
    case selector
      when 'doc1'; "doc\r\n1"
      when 'doc2'; "doc\r\n2"
      when 'dir1'; [ MrGopher.text('dir1/doc3') ]
      when 'dir1/doc3'; "doc\r\n3"
    end
  end

end

EventMachine::run do
  host = 'localhost'
  port = 70
  doc_store = MyDocStore.new

  EventMachine::start_server host, port, MrGopher::Server do |conn|
    conn.default_host = host
    conn.default_port = port
    conn.doc_store = doc_store
  end

end
