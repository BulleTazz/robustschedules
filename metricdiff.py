import re
import argparse

def read_file(file_path):
    """Reads the content of a text file."""
    with open(file_path, 'r') as file:
        return file.read()

def extract_fields(text):
    """Extracts relevant lines from the text file that contain specific keywords."""
    fields = {
        'optimum_found': re.search(r'(OPTIMUM FOUND|UNSOLVABLE|SATISFIABLE|UNKNOWN)', text),
        'optimization': list(map(int, re.search(r'Optimization\s*:\s*((?:-?\d+\s*)+)', text).group(1).split())),
        'time': float(re.search(r'Time\s*:\s*([\d\.]+)s', text).group(1)),
        'cpu_time': float(re.search(r'CPU Time\s*:\s*([\d\.]+)s', text).group(1))
    }
    
    # Extract and clean the fields (handle missing data as None)
    extracted_data = {
        'SOLUTION': fields['optimum_found'].group(0) if fields['optimum_found'] else None,
        'OPTIMIZATIONS': fields['optimization'] if fields['optimization'] else None,
        'Time': fields['time'] if fields['time'] else None,
        'CPU_Time': fields['cpu_time'] if fields['cpu_time'] else None
    }
    
    return extracted_data

def display_fields(file1, fields1, file2, fields2):
    """Displays field values from both files, showing differences clearly."""
    print("#############################")
    print(f"Comparing fields: {file1} vs {file2}")
    print("#############################\n")

    preferred_order = ["SOLUTION", "OPTIMIZATIONS", "Time", "CPU_Time"]
    all_fields = list(set(fields1) | set(fields2))
    ordered_fields = preferred_order + sorted(f for f in all_fields if f not in preferred_order)

    print(f"{'Field':<20} | {file1:<25} | {file2:<25} | Difference")
    print("-" * 95)

    for field in ordered_fields:
        val1 = fields1.get(field, "<missing>")
        val2 = fields2.get(field, "<missing>")

        # Compute the diff meaningfully
        if val1 == val2:
            diff = "Same"
        elif field in ["Time", "CPU_Time"]:
            try:
                v1 = float(val1)
                v2 = float(val2)
                delta = v2 - v1
                sign = "+" if delta > 0 else ""
                diff = f"{sign}{delta:.3f}s"
            except Exception:
                diff = "Error comparing"
        elif field == "OPTIMIZATIONS" and isinstance(val1, list) and isinstance(val2, list):
            added = set(val2) - set(val1)
            removed = set(val1) - set(val2)
            parts = []
            if added:
                parts.append(f"+{sorted(added)}")
            if removed:
                parts.append(f"-{sorted(removed)}")
            diff = " ".join(parts)
        else:
            diff = "Different"

        print(f"{field:<20} | {str(val1):<25} | {str(val2):<25} | {diff}")

    print("\n#############################")
def main(file1, file2):
    # Step 1: Read the files
    file1_text = read_file(file1)
    file2_text = read_file(file2)
    
    # Step 2: Extract relevant fields from each file
    fields_file1 = extract_fields(file1_text)
    fields_file2 = extract_fields(file2_text)
    
    # Step 3: Display the values from both files
    display_fields(file1,fields_file1, file2, fields_file2)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Display relevant computational results from two text files.")
    parser.add_argument("file1", help="Path to the first text file.")
    parser.add_argument("file2", help="Path to the second text file.")
    
    args = parser.parse_args()
    main(args.file1, args.file2)
