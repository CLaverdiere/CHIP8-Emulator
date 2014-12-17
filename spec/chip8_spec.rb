# Chip8 emulator tests.
# Gathered requirements from: http://en.wikipedia.org/wiki/CHIP-8

require "minitest/autorun"
require "minitest/spec"

require_relative "../src/chip8"

SAMPLE_ROM = "games/PONG"

describe CHIP8 do
  before do
    @chip = CHIP8.new

    describe "when starting the CHIP8" do
      it "must have the instruction pointer start at 0x200" do
        @chip.instruction_ptr.must_equal 0x200
      end
    end
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
    it "must have 16, 16-bit values" do
      @chip.stack.size.must_equal 16
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

  describe "when asked about the keypad" do
    it "must have 16 keys" do
      @chip.keypad.size.must_equal 16
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
    it "Should set program_running to false" do
      @chip.kill_program()
      @chip.program_running.must_equal false
    end
  end

  describe "Opcode 00E0" do
    it "Should set all display values to 0" do
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

  describe "Opcode 00EE" do
    it "Should set ins ptr to top of stack, and dec stack ptr" do
      old_ctr = @chip.stack_ptr
      stack_val = @chip.stack[@chip.stack_ptr]
      @chip.do_instruction(0x00EE)
      @chip.instruction_ptr.must_equal stack_val
      @chip.stack_ptr.must_equal (old_ctr - 1)
    end
  end

  describe "Opcode 1NNN" do
    it "Should set instruction pointer to jumped-to address" do
      @chip.do_instruction(0x15e4)
      @chip.instruction_ptr.must_equal 0x5e4
    end
  end

  describe "Opcode 2NNN" do
    it "Should set inc the stack pointer, place the inst ptr on the stack, and set the inst ptr to NNN" do
      old_ip = @chip.instruction_ptr
      old_ctr = @chip.stack_ptr
      @chip.do_instruction(0x254a)
      @chip.stack[@chip.stack_ptr].must_equal old_ip
      @chip.instruction_ptr.must_equal 0x54a
      @chip.stack_ptr.must_equal (old_ctr + 1)
    end
  end

  describe "Opcode 3XNN" do
    it "Should skip the next instruction if VX == NN" do
      orig_ip = @chip.instruction_ptr
      @chip.registers[4] = 5
      @chip.do_instruction(0x3405)
      @chip.instruction_ptr.must_equal orig_ip + 2
    end
  end

  describe "Opcode 4XNN" do
    it "Should skip the next instruction if VX != NN" do
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
      @chip.registers[0xf] = 0
      @chip.registers[4] = 0xff
      @chip.registers[5] = 0x01
      @chip.do_instruction(0x8454)
      @chip.registers[0xf].must_equal 1
    end
  end

  describe "Opcode 8XY5" do
    it "Should subtract VY from VX. Set VF to 0 when borrow, 1 otherwise" do
      @chip.registers[0xf] = 1
      @chip.registers[4] = 0x00
      @chip.registers[5] = 0x01
      @chip.do_instruction(0x8455)
      @chip.registers[0xf].must_equal 0
    end
  end

  describe "Opcode 8XY6" do
    it "Should shift VX right by one. Set VF to the LSB of VX before the shift." do
      @chip.registers[0xf] = 0
      @chip.registers[7] = 0b1011
      @chip.do_instruction(0x8706)
      @chip.registers[7].must_equal 0b101
      @chip.registers[0xf].must_equal 1
    end
  end

  describe "Opcode 8XY6" do
    it "Should set VX to (VY - VX). Set VF to 0 when borrow, otherwise 1" do
      @chip.registers[0xf] = 1
      @chip.registers[4] = 0x01
      @chip.registers[5] = 0x00
      @chip.do_instruction(0x8457)
      @chip.registers[0xf].must_equal 0
    end
  end

  describe "Opcode 8XYE" do
    it "Should shift VX left by one. Set VF to the MSB of VX before the shift." do
      @chip.registers[0xf] = 0
      @chip.registers[7] = 0b1011
      @chip.do_instruction(0x870e)
      @chip.registers[7].must_equal 0b0110
      @chip.registers[0xf].must_equal 1
    end
  end

  describe "Opcode 9XY0" do
    it "Should skip the next instruction if VX != VY." do
      orig_ip = @chip.instruction_ptr
      @chip.registers[4] = 6
      @chip.registers[5] = 7
      @chip.do_instruction(0x9450)
      @chip.instruction_ptr.must_equal orig_ip + 2
    end
  end

  describe "Opcode ANNN" do
    it "Should set the address register to NNN." do
      @chip.do_instruction(0xA450)
      @chip.addr_register.must_equal 0x450
    end
  end

  describe "Opcode BNNN" do
    it "Should set instruction pointer to address NNN + V0" do
      @chip.registers[0] = 7
      @chip.do_instruction(0xB450)
      @chip.instruction_ptr.must_equal 0x450 + @chip.registers[0]
    end
  end

  describe "Opcode CXNN" do
    it "Should set VX to a random number ANDed to NN." do
      @chip.registers[2] = 0x99
      @chip.do_instruction(0xC255)
      @chip.registers[2].must_be :<, 0x55
    end
  end

  # TODO this one is lengthy... I'll do this at the end of testing.
  describe "Opcode DXYN" do
    it "Should do a lot of things" do
    end
  end

  describe "Opcode EX9E" do
    it "Should skip the next instruction if the key stored in VX is pressed." do
      old_ip = @chip.instruction_ptr
      @chip.keypad[5] = 1
      @chip.do_instruction(0xE59E)
      @chip.instruction_ptr.must_equal (old_ip + 2)

      old_ip = @chip.instruction_ptr
      @chip.keypad[4] = 0
      @chip.do_instruction(0xE49E)
      @chip.instruction_ptr.must_equal (old_ip)
    end
  end

  describe "Opcode EXA1" do
    it "Should skip the next instruction if the key stored in VX isn't pressed." do
      old_ip = @chip.instruction_ptr
      @chip.keypad[5] = 0
      @chip.do_instruction(0xE5A1)
      @chip.instruction_ptr.must_equal (old_ip + 2)

      old_ip = @chip.instruction_ptr
      @chip.keypad[4] = 1
      @chip.do_instruction(0xE4A1)
      @chip.instruction_ptr.must_equal (old_ip)
    end
  end

  describe "Opcode FX07" do
    it "Should set VX to the value of the delay timer." do
      @chip.do_instruction(0xF407)
      @chip.registers[4].must_equal @chip.timers[:delay]
    end
  end

  describe "Opcode FX15" do
    it "Should set the delay timer to VX." do
      @chip.do_instruction(0xF715)
      @chip.timers[:delay].must_equal 7
    end
  end

  describe "Opcode FX18" do
    it "Should set the sound timer to VX." do
      @chip.do_instruction(0xF718)
      @chip.timers[:sound].must_equal 7
    end
  end

  describe "Opcode FX1E" do
    it "Should add VX to I" do
      old_ip = @chip.instruction_ptr
      @chip.do_instruction(0xF51E)
      @chip.instruction_ptr.must_equal (old_ip + 5)
    end
  end

  # TODO requires sprite table first
  describe "Opcode FX29" do
    it "Should set I to the location of the sprite for the character in VX. Characters 0-F (in hexadecimal) are represented by a 4x5 font." do
    end
  end

  # TODO requires sprite table first
  describe "Opcode FX33" do
    it "Should store the BCD representation of Vx in memory locations I, I+1, and I+2." do
    end
  end

  describe "Opcode FX55" do
    it "Should store V0 to VX in memory starting at address I." do
      ip = @chip.instruction_ptr
      @chip.registers[0,3] = [2, 7, 6]
      @chip.do_instruction(0xF255)
      @chip.memory[ip, 3].must_equal [2, 7, 6]
    end
  end

  describe "Opcode FX65" do
    it "Should fill V0 to VX with values from memory starting at address I." do
      ip = @chip.instruction_ptr
      @chip.memory[ip,3] = [2, 7, 6]
      @chip.do_instruction(0xF265)
      @chip.registers[0, 3].must_equal [2, 7, 6]
    end
  end

end
