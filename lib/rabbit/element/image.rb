require 'rabbit/image'
require 'rabbit/element/block-element'

module Rabbit
  module Element
    class Image
      include BlockElement
      include BlockHorizontalCentering

      include ImageManipulable

      attr_reader :caption
      attr_reader :normalized_width, :normalized_height
      attr_reader :relative_width, :relative_height

      def initialize(filename, prop)
        super(filename)
        %w(caption dither_mode).each do |name|
          instance_variable_set("@#{name}", prop[name])
        end
        %w(keep_scale keep_ratio).each do |name|
          unless prop[name].nil?
            self.keep_ratio = (prop[name] == "true")
          end
        end
        %w(width height
           x_dither y_dither
           normalized_width normalized_height
           relative_width relative_height
          ).each do |name|
          instance_variable_set("@#{name}", prop[name] && Integer(prop[name]))
        end
        resize(@width, @height)
      end

      def draw_element(canvas, x, y, w, h, simulation)
        draw_image(canvas, x, y, w, h, simulation)
      end

      def text
        @caption.to_s
      end

      def to_html
        return 'image is not supported'
        filename = File.join(base_dir, "XXX.png")
        @loader.pixbuf.save(filename, "png")
        result = "<img "
        result << "title='#{@caption}' " if @caption
        result << "src='#{filename}' />"
        result
      end

      def dither_mode
        @dither_mode ||= "normal"
        mode_name = "DITHER_#{@dither_mode.upcase}"
        if Gdk::RGB.const_defined?(mode_name)
          Gdk::RGB.const_get(mode_name)
        else
          Gdk::RGB::DITHER_NORMAL
        end
      end

      def x_dither
        @x_dither || 0
      end

      def y_dither
        @y_dither || 0
      end

      alias _compile compile
      def compile_for_horizontal_centering(canvas, x, y, w, h)
        _compile(canvas, x, y, w, h)
      end

      def compile(canvas, x, y, w, h)
        super
        adjust_size(canvas, @x, @y, @w, @h)
      end

      def width
        super + @padding_left + @padding_right
      end

      def height
        super + @padding_top + @padding_bottom
      end

      private
      def draw_image(canvas, x, y, w, h, simulation)
        unless simulation
          canvas.draw_pixbuf(pixbuf, x, y)
        end
        [x, y + height, w, h - height]
      end

      def adjust_size(canvas, x, y, w, h)
        base_w = w
        base_h = (@oh || h) - @padding_top - @padding_bottom
        nw = make_normalized_size(@normalized_width)
        nh = make_normalized_size(@normalized_height)
        rw = make_relative_size(@relative_width, base_w)
        rh = make_relative_size(@relative_height, base_h)
        iw = nw || rw
        ih = nh || rh
        resize(iw, ih)
      end

      def make_normalized_size(size)
        size && screen_size(size)
      end

      def make_relative_size(size, parent_size)
        size && parent_size && ((size / 100.0) * parent_size).ceil
      end
    end
  end
end
