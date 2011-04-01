require 'oily_png/canvas'
require 'ft2'

module Glyphr
  class Renderer
    attr_accessor :font, :size, :image_width, :image_height, :h_advance, :v_advance
    attr_reader :face, :image, :glyphs, :glyph_codes, :matrix

    ONE64POINT = 64
    RESOLUTION = 72
    LEFT_MARGIN = 6
    TOP_MARGIN = 70

    def initialize(font = nil, size = 36)
      @font = font
      @size = size
      if font
        setup_ft
      end
    end

    def render(*composition)
      return false if not image_width or not composition

      glyphs_from composition

      render_glyphs

      reset_image

      compose_to_image

      return true
    end

    def render_matrix(matrix)
      return false if not h_advance && v_advance
      @matrix = matrix

      reset_matrix_image

      compose_matrix

      draw_lines
    end

    def reset_image
      @image = OilyPNG::Canvas.new(image_width, image_height, ChunkyPNG::Color::WHITE)
    end

    def reset_matrix_image
      @image_width = @matrix.first.size * h_advance
      @image_height = @matrix.size * v_advance
      reset_image
    end

    def image
      return @image.to_image if @image
    end

    def glyphs_from(composition)
      @glyph_codes = []
      if composition.size == 1
        if composition.first.is_a?(String)
          composition.first.each_codepoint do |c|
            @glyph_codes << face.char_index(c)
          end
        elsif composition.first.is_a?(Array)
          @glyph_codes = composition.first
        end
      else
        @glyph_codes = composition
      end
    end

    private
    # sets up all attributes of freetype
    def setup_ft
      unless face
        @face = FT2::Face.load(@font)
        face.select_charmap(FT2::Encoding::UNICODE)
        face.set_char_size 0, size * ONE64POINT, RESOLUTION, RESOLUTION
      end
    end

    def render_glyphs
      @glyphs = []
      @y_min = 0
      @image_height = 0
      glyph_codes.each do |code|
        face.load_glyph(code, FT2::Load::NO_HINTING)
        glyph = face.glyph.render(FT2::RenderMode::NORMAL)
        x_min, y_min, x_max, y_max = face.glyph.glyph.cbox FT2::GlyphBBox::PIXELS
        @glyphs << {
          :bitmap_top => glyph.bitmap_top,
          :pixels => glyph.bitmap.buffer.bytes.to_a,
          :left => glyph.bitmap_left.to_i,
          :rows => glyph.bitmap.rows,
          :width => glyph.bitmap.width,
          :h_advance => glyph.h_advance
        }
        if (height = (y_max - y_min) + 1) > @image_height
          @image_height = height
        end
        @y_min = y_min if y_min < @y_min
      end
      @image_height -= @y_min
    end

    def compose_to_image
      x = LEFT_MARGIN
      @glyphs.each do |glyph|
        if glyph[:width] > 0
          glyph_image = OilyPNG::Canvas.new(glyph[:width],
                                            glyph[:rows],
                                            glyph[:pixels])
          if x + glyph[:width] + glyph[:left] < image_width
            @image.compose!(glyph_image, x + glyph[:left], (image_height - glyph[:bitmap_top] + @y_min))
          elsif (new_width = image_width - (x + glyph[:left])) > 0
            glyph_image.crop!(0,0,new_width, glyph[:rows])
            @image.compose!(glyph_image, x + glyph[:left], (image_height - glyph[:bitmap_top] + @y_min))
          else
            break
          end
        end
        x = (x + (h_advance || glyph[:h_advance])).to_i
      end
    end

    def compose_matrix
      y = TOP_MARGIN
      matrix.each do |line|
        x = LEFT_MARGIN
        line.each do |code|
          face.load_glyph(code, FT2::Load::NO_HINTING)
          glyph = face.glyph.render(FT2::RenderMode::NORMAL)
          x_min, y_min, x_max, y_max = face.glyph.glyph.cbox FT2::GlyphBBox::PIXELS
          width = x_max - x_min
          if glyph.bitmap.width > 0
            glyph_image = OilyPNG::Canvas.new(glyph.bitmap.width,
                                              glyph.bitmap.rows,
                                              glyph.bitmap.buffer.bytes.to_a)
            @image.compose!(glyph_image, x + (h_advance/2.0 - width/2.0).to_i, y - glyph.bitmap_top)
          end
          x = x + h_advance
        end
        y = y + v_advance
      end
    end

    def draw_lines
      x = h_advance
      (matrix.first.size - 1).times do
        @image.line x, 0, x, image_height, ChunkyPNG::Color.rgb(128, 128, 128)
        x = x + h_advance
      end
      y = (TOP_MARGIN + h_advance/3.0).to_i
      (matrix.size - 1).times do
        @image.line 0, y, image_width, y, ChunkyPNG::Color.rgb(128, 128, 128)
        y = y + v_advance
      end

    end
  end
end

