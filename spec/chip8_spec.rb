# Chip8 emulator tests.
# Gathered requirements from: http://en.wikipedia.org/wiki/CHIP-8

require "minitest/autorun"
require "minitest/spec"

require_relative "../src/chip8"

SAMPLE_ROM = "games/PONG"

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
    it "must be able to find matching opcode when given hex number" do
      opcode = 0x00e0
      @chip.get_opcode(opcode).wont_be_nil
    end

    it "must be able to print the opcode's description when passed" do
      opcode = 0x00e0
      @chip.get_opcode_desc(opcode).wont_be_nil
    end
  end

  describe "when loading in a rom" do
    it "must fill the memory buffer with opcode data" do
      @chip.load_rom(SAMPLE_ROM)
      @chip.memory.inject(:+).wont_equal 0
    end
  end

  describe "when executing instructions" do
    it "must increment the instruction pointer" do
      current_ip = @chip.instruction_ptr
      @chip.next_instruction()
      current_ip.must_equal @chip.instruction_ptr - 2
    end
  end

  describe "when killing the program" do
    it "should set program_running to false" do
      @chip.kill_program()
      @chip.program_running.must_equal false
    end
  end

end
