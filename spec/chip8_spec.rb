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
      @chip.memory.reduce(:+).wont_equal 0
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

  describe "Opcode 00E0" do
    it "should set all display values to 0" do
      @chip.do_instruction(0x00e0)
      total = 0
      @chip.display.each do |row|
        row.each do |col|
          total += col
        end
      end

      total.must_equal 0
    end
  end

  describe "Opcode 1NNN" do
    it "should set instruction pointer to jumped-to address" do
      @chip.do_instruction(0x15e4)
      @chip.instruction_ptr.must_equal 0x5e4
    end
  end

  describe "Opcode 3XNN" do
    it "should skip the next instruction if VX == NN" do
      orig_ip = @chip.instruction_ptr
      @chip.registers[4] = 5
      @chip.do_instruction(0x3405)
      @chip.instruction_ptr.must_equal orig_ip + 2
    end
  end

  describe "Opcode 4XNN" do
    it "should skip the next instruction if VX != NN" do
      orig_ip = @chip.instruction_ptr
      @chip.registers[4] = 6
      @chip.do_instruction(0x4405)
      @chip.instruction_ptr.must_equal orig_ip + 2
    end
  end

  describe "Opcode 5XY0" do
    it "Should skip the next instruction if VX == VY." do
      orig_ip = @chip.instruction_ptr
      @chip.registers[4] = 6
      @chip.registers[5] = 6
      @chip.do_instruction(0x5450)
      @chip.instruction_ptr.must_equal orig_ip + 2
    end
  end

  describe "Opcode 6XNN" do
    it "Should set VX to NN" do
      @chip.do_instruction(0x6199)
      @chip.registers[1].must_equal 0x99
    end
  end

  describe "Opcode 7XNN" do
    it "Should add NN to VX" do
      @chip.registers[1] = 44
      @chip.do_instruction(0x7101)
      @chip.registers[1].must_equal 45
    end
  end

  describe "Opcode 8XY0" do
    it "Should set VX to VY" do
      @chip.registers[5] = 12
      @chip.do_instruction(0x8450)
      @chip.registers[4].must_equal 12
    end
  end

  describe "Opcode 8XY1" do
    it "Should set VX to (VX or VY)" do
      @chip.registers[4] = 0x10
      @chip.registers[5] = 0x01
      @chip.do_instruction(0x8451)
      @chip.registers[4].must_equal 0x11
    end
  end

  describe "Opcode 8XY2" do
    it "Should set VX to (VX and VY)" do
      @chip.registers[4] = 0x10
      @chip.registers[5] = 0x01
      @chip.do_instruction(0x8452)
      @chip.registers[4].must_equal 0x00
    end
  end

  describe "Opcode 8XY3" do
    it "Should set VX to (VX xor VY)" do
      @chip.registers[4] = 0x11
      @chip.registers[5] = 0x01
      @chip.do_instruction(0x8453)
      @chip.registers[4].must_equal 0x10
    end
  end

  describe "Opcode 8XY4" do
    it "Should add VY to VX. VF set to 1 when carry, 0 otherwise" do
      @chip.registers[4] = 0xff
      @chip.registers[5] = 0x01
      @chip.do_instruction(0x8454)
      @chip.registers[0xf].must_equal 1
    end
  end

end
