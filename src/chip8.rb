# Chip8 emulator class.

class CHIP8
  attr_accessor :addr_register,
                :display,
                :instruction_ptr,
                :keypad,
                :memory,
                :program_running,
                :registers,
                :stack,
                :stack_ptr

  attr_reader :opcode_table, 
              :timers

  def initialize()
    @addr_register = 0
    @display = [[0] * 0x40] * 0x20
    @keypad = [0] * 0x10
    @instruction_ptr = 0x200
    @memory = [0] * 0x1000
    @opcode_table = make_opcode_descs()
    @program_running = true
    @registers = [0] * 0x10
    @stack = [0] * 0x10
    @stack_ptr = 0
    @timers = {delay: 0x40, sound: 0x40}
  end

  # Execute the given instruction.
  def do_instruction(opcode)
    sym_op = get_opcode(opcode)

    # Byte components
    b1 = (opcode & 0xf000) >> 12
    b2 = (opcode & 0x0f00) >> 8
    b3 = (opcode & 0x00f0) >> 4
    b4 = (opcode & 0x000f)

    # print "Op: ", sym_op, " | "
    # print "Desc: ", get_opcode_desc(opcode), "\n"

    # Massive opcode conditional incoming.
    case sym_op

    when "00E0"
      # Clear the screen.
      @display.each do |row|
        row.each do |col|
          col = 0
        end
      end

    when "00EE"
      # Return from a subroutine.
      @instruction_ptr = @stack[@stack_ptr]
      @stack_ptr -= 1;

    when "0NNN"
      # This one isn't actually used by games. Skip it.

    when "1NNN"
      # Jump to address NNN.
      @instruction_ptr = opcode & 0x0fff

    when "2NNN"
      # Call subroutine at NNN.
      @stack_ptr += 1
      @stack[@stack_ptr] = @instruction_ptr
      @instruction_ptr = opcode & 0x0fff

    when "3XNN"
      # Skips next instruction if VX == NN.
      if @registers[b2] == opcode & 0x00ff
        @instruction_ptr += 2
      end

    when "4XNN"
      # Skips next instruction if VX != NN.
      if @registers[b2] != opcode & 0x00ff
        @instruction_ptr += 2
      end

    when "5XY0"
      # Skips next instruction if VX == VY.
      if @registers[b2] == @registers[b3]
        @instruction_ptr += 2
      end

    when "6XNN"
      # Sets VX to NN.
      @registers[b2] = opcode & 0x00ff

    when "7XNN"
      # Adds NN to VX.
      @registers[b2] += opcode & 0x00ff

    when "8XY0"
      # Sets VX to VY.
      @registers[b2] += @registers[b3]

    when "8XY1"
      # Sets VX to (VX or VY).
      @registers[b2] |= @registers[b3]

    when "8XY2"
      # Sets VX to (VX and VY).
      @registers[b2] &= @registers[b3]

    when "8XY3"
      # Sets VX to (VX xor VY).
      @registers[b2] ^= @registers[b3]

    when "8XY4"
      # Adds VY to VX. Sets VF to 1 when carry, 0 otherwise.
      # Only keep lowest 8 bits.
      @registers[b2] += @registers[b3]
      if @registers[b2] > 0xff
        @registers[0xf] = 1
      else
        @registers[0xf] = 0
      end
      @registers[b2] &= 0xff

    when "8XY5"
      # Subtracts VY from VX. Sets VF to 0 when borrow, 1 otherwise.
      # Only keep lowest 8 bits.
      @registers[b2] -= @registers[b3]
      if @registers[b2] < 0
        @registers[0xf] = 0
      else
        @registers[0xf] = 1
      end
      @registers[b2] &= 0xff

    when "8XY6"
      # Shifts VX right by one. Sets VF to the LSB of VX before the shift.
      @registers[0xf] = @registers[b2] % 2
      @registers[b2] >>= 1

    when "8XY7"
      # Sets VX to (VY - VX). Sets VF to 0 when borrow, otherwise 1.
      # Only keep lowest 8 bits.
      @registers[b2] = @registers[b3] - @registers[b2]
      if @registers[b2] < 0
        @registers[0xf] = 0
      else
        @registers[0xf] = 1
      end
      @registers[b2] &= 0xff

    when "8XYE"
      # Shifts VX left by one. Sets VF to the MSB of VX before the shift.
      @registers[0xf] = (@registers[b2] / 0b1000 > 0 ? 1 : 0)
      @registers[b2] = @registers[b2] << 1 & 0b0111

    when "9XY0"
      # Skips next instruction if VX == VY.
      if @registers[b2] != @registers[b3]
        @instruction_ptr += 2
      end

    when "ANNN"
      # Set address register to NNN.
      @addr_register = opcode & 0x0fff

    when "BNNN"
      # Set instruction pointer to address NNN + V0
      @instruction_ptr = (opcode & 0x0fff) + @registers[0]

    when "CXNN"
      # Set VX to a random number and NN.
      @registers[b2] = [*0..(opcode & 0x00ff)].sample

    when "DXYN"
      # TODO this should draw sprites, not just memory bits.
      # Draw N bytes of sprites starting from address register I,
      #   at coordinates VX, VY. XORd onto screen. If any sprites overwritten,
      #   set VF to 1, otherwise, 0. Wrap sprites if they go outside coordinates.
      overwritten = 0
      for i in 0..b4
        col_offset = (b2 + i) / 0x40
        new_row = (b3 + col_offset) % 0x20
        new_col = b2 % 0x40
        old_pixel = @display[new_row][new_col]
        new_pixel = @memory[@addr_register+i]
        result = old_pixel ^ new_pixel

        @display[new_row][new_col] = result
        if old_pixel == 1 and new_pixel == 0
          overwritten = 1
        end
      end

      @registers[0xf] = overwritten

    when "EX9E"
      # Skip the next instruction if the key stored in VX is pressed.
      if keypad[b2] == 1
        @instruction_ptr += 2
      end

    when "EXA1"
      # Skip the next instruction if the key stored in VX isn't pressed.
      if keypad[b2] == 0
        @instruction_ptr += 2
      end

    when "FX07"
      # Set VX to the value of the delay timer.
      @registers[b2] = @timers[:delay]

    # TODO
    when "FX0A"
      # A key press is awaited, and then stored in VX.

    when "FX15"
      # Sets the delay timer to VX.
      @timers[:delay] = b2

    when "FX18"
      # Sets the sound timer to VX.
      @timers[:sound] = b2

    when "FX1E"
      # Adds VX to I
      @instruction_ptr += b2

    # TODO
    when "FX29"
      # Set I to the location of the sprite for the character in VX. Characters
      # 0-F (in hexadecimal) are represented by a 4x5 font.

    # TODO
    when "FX33"
      # Store the BCD representation of Vx in memory locations I, I+1, and I+2.
      # The interpreter takes the decimal value of Vx, and places the hundreds
      # digit in memory at location in I, the tens digit at location I+1, and
      # the ones digit at location I+2.

    when "FX55"
      # Store V0 to VX in memory starting at address I.
      for i in 0..b2
        @memory[@instruction_ptr + i] = @registers[i]
      end

    when "FX65"
      # Fill V0 to VX with values from memory starting at address I.
      for i in 0..b2
        @registers[i] = @memory[@instruction_ptr + i]
      end
    end
  end

  # Input: a hex opcode. ex: 0x5f3e
  # Output: The matching symbolic opcode from our opcode table.
  # Since our opcode table stores symbols, like 'X', 'Y', and 'N',
  #   we just do a naive word score to get the closest matching opcode.
  # Linear time, but I'm willing to do this to avoid having a messy bit-parsing
  #   function.
  def get_opcode(opcode)
    formatted_opcode = "0000"
    formatted_opcode[4 - opcode.to_s(16).length, 4] = opcode.to_s(16).upcase
    match = @opcode_table.sort_by { |oc| score_word(oc[0], formatted_opcode) }
    return match.last[0]
  end

  # Return description of supplied opcode from table.
  def get_opcode_desc(opcode)
    sym_opcode = get_opcode(opcode)
    return @opcode_table[sym_opcode]
  end

  def kill_program()
    @program_running = false
  end

  # Load ROM file into memory.
  def load_rom(rom_filename)
    rom_file = File.new(rom_filename, "r")
    memcnt = @instruction_ptr
    while (opcode = rom_file.read(2))
      opcode_bytes = opcode.bytes.to_a
      @memory[memcnt] = opcode_bytes[0]
      @memory[memcnt+1] = opcode_bytes[1]
      memcnt += 2
    end
  end

  # Generate opcode descriptions from a plaintext file of format:
  #   OPCODE | DESCRIPTION
  # ...which I stole off Wikipedia.
  def make_opcode_descs()
    opcode_table = Hash.new
    desc_file = File.open(File.expand_path("spec/opcodes.txt"), "r")
    desc_file.each_line do |line|
      opcode, desc = line.split('|')
      opcode_table[opcode.strip] = desc.strip
    end
    return opcode_table
  end

  # Executes the next instruction in memory.
  # We must construct the opcode from two adjacent bytes in memory.
  # Most significant byte stored first (big-endian).
  def next_instruction()
    opcode = (@memory[@instruction_ptr] << 8) + @memory[@instruction_ptr+1]

    if opcode == 0
      kill_program()
    end

    do_instruction(opcode)
    @instruction_ptr += 2
  end

  # Score a word, weighing earlier characters heavier.
  def score_word(a, b)
    count = 0
    a.split('').each_index do |i|
      if a[i] == b[i]
        count += (a.length - i)
      end
    end
    return count
  end
end
