# Chip8 emulator class.

class CHIP8
  attr_accessor :display, :instruction_ptr, :memory, :program_running, :registers, :stack
  attr_reader :opcode_table, :timers

  def initialize()
    @display = [[0] * 0x40] * 0x20
    @instruction_ptr = 0
    @memory = [0] * 0x1000
    @registers = [0] * 0x10
    @stack = [0] * 0x40
    @timers = {delay: 0x40, sound: 0x40}
    @opcode_table = make_opcode_descs()
    @program_running = true
  end

  # Execute the given instruction.
  def do_instruction(opcode)
    sym_op = get_opcode(opcode)

    # n1 = (opcode & 0xf000) >> 12
    # n2 = (opcode & 0x0f00) >> 8
    # n3 = (opcode & 0x00f0) >> 4
    # n4 = (opcode & 0x000f)

    print "Op: ", sym_op, " | "
    print "Desc: ", get_opcode_desc(opcode), "\n"

    # Massive opcode conditional incoming.
    case sym_op
    when nil
      kill_program()
    when "00E0"
    when "00EE"
    when "0NNN"
    when "1NNN"
    when "2NNN"
    when "3XNN"
    when "4XNN"
    when "5XY0"
    when "6XNN"
    when "7XNN"
    when "8XY0"
    when "8XY1"
    when "8XY2"
    when "8XY3"
    when "8XY4"
    when "8XY5"
    when "8XY6"
    when "8XY7"
    when "8XYE"
    when "9XY0"
    when "ANNN"
    when "BNNN"
    when "CXNN"
    when "DXYN"
    when "EX9E"
    when "EXA1"
    when "FX07"
    when "FX0A"
    when "FX15"
    when "FX18"
    when "FX1E"
    when "FX29"
    when "FX33"
    when "FX55"
    when "FX65"
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
    memcnt = 0
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
