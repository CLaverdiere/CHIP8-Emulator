# Opcode Names
# ["00E0", "00EE", "0NNN", "1NNN", "2NNN", "3XNN", "4XNN",
#  "5XY0", "6XNN", "7XNN", "8XY0", "8XY1", "8XY2", "8XY3",
#  "8XY4", "8XY5", "8XY6", "8XY7", "8XYE", "9XY0", "ANNN",
#  "BNNN", "CXNN", "DXYN", "EX9E", "EXA1", "FX07", "FX0A",
#  "FX15", "FX18", "FX1E", "FX29", "FX33", "FX55", "FX65"]

class CHIP8
  attr_reader :display, :memory, :opcode_table, :registers, :stack, :timers

  def initialize()
    @display = [[0b0] * 0x40] * 0x20
    @memory = [0x00] * 0x1000
    @registers = [0x00] * 0x10
    @stack = [0x00] * 0x40
    @timers = {delay: 0x40, sound: 0x40}
    @opcode_table = make_opcode_descs()
  end

  # Input: a hex opcode. ex: 0x5f3e
  # Output: The description closest matching the supplied opcode.
  # Since our opcode table stores symbols, like 'X', 'Y', and 'N',
  #   we just do a naive word score to get the closest matching opcode.
  def get_opcode_desc(opcode)
    formatted_opcode = "0000"
    formatted_opcode[4 - opcode.to_s(16).length, 4] = opcode.to_s(16).upcase
    match = @opcode_table.sort_by { |oc| score_word(oc[0], formatted_opcode) }
    return match.last[1]
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

  # Execute the given instruction.
  def do_instruction(opcode)
    n1 = (opcode & 0xf000) >> 12
    n2 = (opcode & 0x0f00) >> 8
    n3 = (opcode & 0x00f0) >> 4
    n4 = (opcode & 0x000f)

    # This was a lazy idea. Going to delete this asap.
    # case n1
    # when 0x0
    #   case n3
    #   when 0xe
    #     case n4
    #     when 0x0
    #       # 00E0
    #     when 0xe
    #       # 00EE
    #     end
    #   else
    #     # 0NNN
    #   end
    #
    # when 0x1
    #   # 1NNN
    #
    # when 0x2
    #   # 2NNN
    #
    # when 0x3
    #   # 3XNN
    #
    # when 0x4
    #   # 4XNN
    #
    # when 0x5
    #   # 5XY0
    #
    # when 0x6
    #   # 6XNN
    #
    # when 0x7
    #   # 7XNN
    #
    # when 0x8
    #   case n4
    #   when 0x0
    #     #8XY0
    #   when 0x1
    #     #8XY1
    #   when 0x2
    #     #8XY2
    #   when 0x3
    #     #8XY3
    #   when 0x4
    #     #8XY4
    #   when 0x5
    #     #8XY5
    #   when 0x6
    #     #8XY6
    #   when 0x7
    #     #8XY7
    #   when 0xe
    #     #8XYE
    #   end
    #
    # when 0x9
    #   # 9XY0
    #
    # when 0xa
    #   # ANNN
    #
    # when 0xb
    #   # BNNN
    #
    # when 0xc
    #   # CXNN
    #
    # when 0xd
    #   # DXYN
    #
    # when 0xe
    #   case n3
    #   when 0x9
    #     # EX9E
    #   else
    #     # EXA1
    #   end
    #
    # when 0xf
    #   case n3
    #   when 0x0
    #     case n4
    #     when 0x7
    #       # FX07
    #     when 0xa
    #       # FX0A
    #     end
    #   when 0x1
    #     case n4
    #     when 0x5
    #       # FX15
    #     when 0x8
    #       # FX18
    #     when 0xe
    #       # FX1E
    #     end
    #   when 0x2
    #     # FX29
    #   when 0x3
    #     # FX33
    #   when 0x5
    #     # FX55
    #   when 0x6
    #     # FX65
    #   end
    #
    # else
    #   # No match
    #   return 1
    # end
  end
end
