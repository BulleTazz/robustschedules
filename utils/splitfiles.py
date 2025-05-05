def split_file_by_keyword(input_file, output_dir, keyword="Answer"):
    import os

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    with open(input_file, 'r') as file:
        lines = file.readlines()

    block = []  # To hold lines of the current block
    block_number = 0

    for line in lines:
        if keyword in line:  # Start a new block whenever the keyword is found
            if block:  # If there's an existing block, save it
                output_file = os.path.join(output_dir, f"model_{block_number}.txt")
                with open(output_file, 'w') as f:
                    f.writelines(block)
                block_number += 1
                block = []  # Reset the block
        block.append(line)  # Add the line to the current block

    # Save the last block if it exists
    if block:
        output_file = os.path.join(output_dir, f"model_{block_number}.txt")
        with open(output_file, 'w') as f:
            f.writelines(block)

    print(f"File split into {block_number + 1} blocks, saved in {output_dir}.")

# Example usage:
# split_file_by_keyword("input.txt", "output_blocks")


split_file_by_keyword("sol", "output")