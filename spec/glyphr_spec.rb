#encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/glyphr')

describe Glyphr::Renderer do
  it 'can be initiated' do
    Glyphr::Renderer.new.should_not be_nil
  end

  it 'can be initiated with font and size' do
    Glyphr::Renderer.new(font_file, 36).should_not be_nil
  end

  context 'Initialized' do
    let (:renderer) { Glyphr::Renderer.new(font_file, 36) }

    it 'returns font' do
      renderer.font.should == font_file
    end

    it 'returns size' do
      renderer.size.should == 36
    end
  end

  context 'Rendering' do
    let (:renderer) {Glyphr::Renderer.new(font_file, 36)}

    it 'accepts image width' do
      renderer.image_width = 100
    end

    it 'render method accepts text' do
      renderer.render('Hello world')
    end

    it 'returns false for render when image size not set' do
      renderer.render('Hello world').should be_false
    end

    it 'returns true for render when image size set' do
      renderer.image_width = 100
      renderer.render('Hello world').should be_true
    end

    it 'renders high chars' do
      renderer.image_width = 100
      renderer.render('Eble ĉiu kvazaŭ-deca fuŝĥoraĵo ĝojigos homtipon.')
    end

    it 'returns nil for image when not rendered' do
      renderer.image.should be_nil
    end

    it 'should render just one glyph' do
      renderer.image_width = 100
      renderer.render(11).should be_true
    end

    it "can set background color" do
      renderer.background_color = ChunkyPNG::Color::BLACK
      renderer.background_color.should == ChunkyPNG::Color::BLACK
    end

    it "can set foreground color" do
      renderer.foreground_color = ChunkyPNG::Color::WHITE
      renderer.foreground_color.should == ChunkyPNG::Color::WHITE
    end
  end

  context 'After rendering' do
    let (:renderer) { Glyphr::Renderer.new(font_file, 36) }

    before do
      renderer.image_width = 100
      renderer.render('Hello world')
    end

    it 'returns image when rendered' do
      renderer.image.should_not be_nil
    end

    it 'returns Chunky PNG image with after render' do
      renderer.image.should be_kind_of ChunkyPNG::Canvas
    end

    it 'can reset image' do
      renderer.reset_image.should_not be_nil
    end
  end

  context 'With freetype' do
    let (:renderer) { Glyphr::Renderer.new(font_file, 36) }

    it 'has freetype face for font' do
      renderer.face.should be_kind_of FT2::Face
    end

    it 'return glyphs count' do
      renderer.face.glyphs.should == 367
    end
  end

  context 'Rendering text' do
    let(:renderer) { Glyphr::Renderer.new("spec/fixtures/metalista.otf", 72) }

    it 'should render same image as in fixture' do
      renderer.image_width = 280
      renderer.render('hello world')
      renderer.image.save('output.png')

      FileUtils.compare_file('output.png', 'spec/fixtures/output.png').should be_true
    end

    after { FileUtils.rm('output.png') }
  end

  context "Rendering with not default colors" do
    let(:renderer) { Glyphr::Renderer.new("spec/fixtures/metalista.otf", 72) }

    it "renders image with non default background and foreground color" do
      renderer.image_width = 280
      renderer.background_color = ChunkyPNG::Color::BLACK
      renderer.foreground_color = ChunkyPNG::Color(250, 240, 241)
      renderer.render('hello world')
      renderer.image.save('output.png')
      FileUtils.compare_file('output.png', 'spec/fixtures/inverse.png').should be_true
    end

  end

  context 'Rendering array of glyphs' do
    let(:renderer) { Glyphr::Renderer.new("spec/fixtures/metalista.otf", 72) }

    before { renderer.image_width = 280 }

    it 'renderers same image as in fixture' do
      renderer.render(11, 133, 140, 140, 143, 3, 26, 143, 146, 140, 132)
      renderer.image.save('output.png')
      FileUtils.compare_file('output.png', 'spec/fixtures/output.png').should be_true
    end

    it 'renders when composition is array' do
      arr = [11, 133, 140, 140, 143, 3, 26, 143, 146, 140, 132]
      renderer.render(arr)
      renderer.image.save('output.png')
      FileUtils.compare_file('output.png', 'spec/fixtures/output.png').should be_true
    end

    after { FileUtils.rm('output.png') }
  end

  context 'Converting text to glyphs array' do
    let(:renderer) { renderer = Glyphr::Renderer.new("spec/fixtures/metalista.otf", 72) }

    it 'converts string to glyphs array' do
      renderer.glyphs_from(['Hello World'])
      renderer.glyph_codes.should == [11, 133, 140, 140, 143, 3, 26, 143, 146, 140, 132]
    end
  end

  context 'Matrix image computing' do
    let(:renderer) { renderer = Glyphr::Renderer.new("spec/fixtures/metalista.otf", 48) }

    before do
      renderer.h_advance = 110
      renderer.v_advance = 110
      renderer.items_per_line = 7
    end

    it 'computes width for matrix image' do
      renderer.render_matrix([10, 11, 12, 13, 14, 15, 16, 17])
      renderer.image_width.should == 770
    end

    it 'computes height for matrix image' do
      renderer.render_matrix([10, 11, 12, 13, 14, 15, 16, 17])
      renderer.image_height.should == 220
    end

    it 'returns number of really rendered lines' do
      renderer.render_matrix([10, 11, 12, 13, 14, 15, 16, 17])
      renderer.lines.should == 2
    end

    it "can render without lines between glyphs" do
      renderer.render_matrix([10, 11, 12, 13, 14, 15, 16, 17], false)
    end

    it "has top margin" do
      renderer.top_margin.should eq 70
    end

    it "can set top margin" do
      renderer.top_margin = 0
      renderer.top_margin.should be_zero
    end
  end

  context 'Rendering to grid' do
    let(:renderer) { Glyphr::Renderer.new("spec/fixtures/metalista.otf", 48) }

    it 'renders on constant horizontal advance' do
      renderer.image_width = 740
      renderer.h_advance = 70
      renderer.render('hello world')
      renderer.image.save('output.png')
      FileUtils.compare_file('output.png', 'spec/fixtures/advance_output.png').should be_true
    end

    it 'renders matrix of glyph codes' do
      renderer.h_advance = 110
      renderer.v_advance = 110
      renderer.items_per_line = 4
      renderer.render_matrix([10, 11, 12, 13, 14, 15, 16, 17])
      renderer.image.save('output.png')
      FileUtils.compare_file('output.png', 'spec/fixtures/matrix_output.png').should be_true
    end

    after { FileUtils.rm('output.png') }
  end

end
