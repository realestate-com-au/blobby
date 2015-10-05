require "blobby/filesystem_store"
require "blobby/store_behaviour"
require "tmpdir"

describe Blobby::FilesystemStore do

  around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
      @tmpdir = nil
    end
  end

  around(:each) do |example|
    original_umask = File.umask
    begin
      File.umask(0077) # something stupid
      example.run
    ensure
      File.umask(original_umask)
    end
  end

  subject do
    described_class.new(@tmpdir)
  end

  it_behaves_like Blobby::Store

  let(:key) { "NAMESPACED/KEY" }
  let(:content) { "CONTENT" }

  let(:expected_file_path) { Pathname(@tmpdir) + key }

  describe "#write" do

    it "writes to the file-system" do
      expect do
        subject[key].write(content)
      end.to change { expected_file_path.exist? }.from(false).to(true)
    end

    it "should have correct contents" do
      expect do
        subject[key].write(content)
      end.to change { File.read(expected_file_path) rescue nil }.from(nil).to(content)
    end

    it "retries if renaming throws an ESTALE" do
      raise_stack = [Errno::ESTALE]
      expect_any_instance_of(Pathname).to receive(:rename).twice do |_args|
        fail(raise_stack.shift) unless raise_stack.empty?
        1
      end
      expect { subject[key].write(content) }.to_not raise_error
    end

  end

  context "with a sharding strategy" do

    subject do
      described_class.new(@tmpdir) do |key|
        [key[0, 2], key[2, 2], key[4, 2], key].join "/"
      end
    end

    describe "#write" do

      let(:key) { "aabbccdd.png" }
      let(:expected_file_path) { Pathname(@tmpdir) + "aa/bb/cc/aabbccdd.png" }

      before do
        subject[key].write(content)
      end

      it "uses the key as the filename" do
        expect(expected_file_path).to exist
      end

    end

  end

  context "when the directory doesn't exist" do

    subject do
      described_class.new("/tmp/bogus/directory")
    end

    it { is_expected.not_to be_available }

  end

  context "when the directory isn't writable" do

    around do |example|
      FileUtils.chmod(0500, @tmpdir)
      example.run
      FileUtils.chmod(0700, @tmpdir)
    end

    it { is_expected.not_to be_available }

  end

  context "when the directory isn't readable" do

    around do |example|
      FileUtils.chmod(0300, @tmpdir)
      example.run
      FileUtils.chmod(0700, @tmpdir)
    end

    it { is_expected.not_to be_available }

  end

  context "when the path isn't a directory" do

    subject do
      tempfile = "#{@tmpdir}/tempfile"
      FileUtils.touch(tempfile)
      described_class.new(tempfile)
    end

    it { is_expected.not_to be_available }

  end

  context "when an IO error occurs" do

    before do
      allow_any_instance_of(IO).to receive(:write) do
        fail IOError
      end
    end

    describe "#write" do

      before do
        expect do
          subject[key].write(content)
        end.to raise_error(IOError)
      end

      it "doesn't write anything" do
        expect(subject[key]).not_to exist
      end

    end

  end

  def mode_string_of(path)
    format("0%o", path.stat.mode & 0777)
  end

  context "with a umask of 0027" do

    subject do
      described_class.new(@tmpdir, :umask => 0027)
    end

    it "has the specified umask" do
      expect(subject.umask).to eq(0027)
    end

    describe "#write" do

      before do
        subject[key].write(content)
      end

      it "creates files with mode 0640" do
        expect(mode_string_of(expected_file_path)).to eq("0640")
      end

      it "creates directories with mode 0750" do
        expect(mode_string_of(expected_file_path.parent)).to eq("0750")
      end

    end

  end

  context "without an explicit umask" do

    let(:system_umask) { 0024 }

    around(:each) do |example|
      original_umask = File.umask
      begin
        File.umask(system_umask)
        example.run
      ensure
        File.umask(original_umask)
      end
    end

    it "uses the system default umask" do
      expect(subject.umask).to eq(system_umask)
    end

  end

end
