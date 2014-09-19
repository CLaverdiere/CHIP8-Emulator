# Gathered requirements from: http://en.wikipedia.org/wiki/CHIP-8

require "minitest/autorun"
require "minitest/spec"

require_relative "../src/chip8"

describe CHIP8 do
  before do
    @chip = CHIP8.new
  end

  describe "when asked about memory" do
    it "must have 4096, 8-bit memory locations" do
      @chip.memory.size.must_equal 4096
      @chip.memory.sample.must_be :<=, 255
    end
  end

  describe "when asked about registers" do
    it "must have 16, 8-bit data registers" do
      @chip.registers.size.must_equal 16
      @chip.registers.sample.must_be :<=, 255
    end
  end

  describe "when asked about the stack" do
    it "must have 64 bytes" do
      @chip.stack.size.must_equal 64
    end
  end

  describe "when asked about its timers" do
    it "must have delay and sound timers" do
      @chip.timers[:delay].wont_be_nil
      @chip.timers[:sound].wont_be_nil
    end
  end

  describe "when asked about the display" do
    it "must have 64x32 pixels" do
      @chip.display.size.must_equal 32
      @chip.display.sample.size.must_equal 64
    end
  end

  describe "when asked about opcodes" do
    it "must be able to print the opcode's description when passed" do
      opcode = 0x00e0
      @chip.get_opcode_desc(opcode).wont_be_nil
    end
  end
end
