#!/bin/bash

# Declare associative arrays to keep track of selected options and their parameters
declare -A selected
declare -A params

# Declare an array to store the priority order
declare -a priority

while true; do
    clear
    echo "========================"
    echo "      MAIN MENU       "
    echo "========================"
    echo "1) Optimization Settings"
    echo "2) Run Solver"
    echo "3) Choose Solution File"
    echo "4) Compare solutions"
    echo "0) Exit"
    echo "========================"
    read -p "Choose an option (1-3, 0 to exit): " main_choice

    case $main_choice in
        1)
            while true; do
                clear
                echo "========================"
                echo "  OPTIMIZATION MENU   "
                echo "========================"
                echo "1) Reduce Delay Propagation ${selected[1]:-}" 
                echo "2) Transfer window ${selected[2]:-}"
                echo "3) Number of Segments ${selected[3]:-}"
                echo "4) Set Priority Order"
                echo "5) Export Configuration"
                echo "0) Back to Main Menu"
                echo "========================"
                read -p "Choose an option (1-5, 0 to return): " choice

                case $choice in
                    1)
                        if [[ "${selected[1]}" == "✔" ]]; then
                            read -p "Undo selection for Reduce Delay Propagation? (y/n): " confirm
                            if [[ "$confirm" == "y" ]]; then
                                unset selected[1]
                                unset params[1]
                                echo "Selection undone."
                            fi
                        else
                            selected[1]="✔"
                            read -p "Enter travel buffer (in seconds): " params[1]
                            echo "Reduce Delay Propagation - Travel Buffer: ${params[1]} seconds" 
                        fi
                        ;;
                    2)
                        if [[ "${selected[2]}" == "✔" ]]; then
                            read -p "Undo selection for ConnectTransfer window? (y/n): " confirm
                            if [[ "$confirm" == "y" ]]; then
                                unset selected[2]
                                unset params[2]
                                echo "Selection undone."
                            fi
                        else
                            selected[2]="✔"
                            read -p "Enter transfer window buffer (in seconds): " params[2]
                            echo "Transfer window - Waiting buffer: ${params[2]} seconds" 
                        fi
                        ;;
                    3)
                        if [[ "${selected[3]}" == "✔" ]]; then
                            read -p "Undo selection for Number of Segments? (y/n): " confirm
                            if [[ "$confirm" == "y" ]]; then
                                unset selected[3]
                                unset params[3]
                                echo "Selection undone."
                            fi
                        else
                            selected[3]="✔"
                            read -p "Choose to maximize or minimize the number of segments (enter 'maximize' or 'minimize'): " params[3]
                            echo "Number of Segments parameter: ${params[3]}" 
                        fi
                        ;;
                    4)
                        echo "Set priority order:"
                        read -p "Reduce Delay Propagation:" priority[1] 
                        read -p "Transfer window:" priority[2]
                        read -p "Number of Segments:" priority[3]  
                        echo "Priority order set: ${priority[@]}"
                        ;;
                    5)
                        echo "Exporting Configuration..."
                        mkdir -p "encodings/encoding"
                        file_name="encodings/encoding/robustness.lp"
                        touch "$file_name"
                        echo "%Robustness Configuration Export" > "$file_name"
                        echo "1{slack(0); slack(${params[1]}000)}1." >> "$file_name";
                        echo "#maximize{S@${priority[1]}: slack(S)}." >> "$file_name";
                        echo "1{window(0); window(${params[2]}000)}1." >> "$file_name";
                        echo "#maximize{Win@${priority[2]}: window(Win)}." >> "$file_name";
                        echo "visited_count(C) :- C = #count { V : visit(T,V) }." >> "$file_name"
                        if [[ "${params[3]}" == "maximize" ]]; then
                            echo "#maximize { C@${priority[3]} : visited_count(C) }." >> "$file_name"
                        else
                            echo "#minimize { C@${priority[3]} : visited_count(C) }." >> "$file_name"
                        fi
                        echo "Configuration exported to $file_name"
                        read -p "Press Enter to return to menu..."
                        ;;
                    0)
                        break
                        ;;
                    *)
                        echo "Invalid choice. Please enter a number between 0 and 5."
                        ;;
                esac
            done
            ;;
        2)
            echo "Available instance files:"
            select instance_file in instances/*.json; do
                if [[ -n "$instance_file" ]]; then
                    instance_file_name="$(basename "$instance_file")"
                    echo "Selected instance file: $instance_file_name"
                    break
                fi
            done

            solution_name=""

            for i in "${!params[@]}"; do
                if [[ -n "${params[$i]}" ]]; then
                    solution_name+="_${params[$i]}"
                fi
            done
      
            
            solution_name="${instance_file_name}${solution_name}"
            
            echo "Running solver..."
            ./solve_and_check.sh $instance_file $solution_name
            read -p "Press Enter to continue..."
            ;;
        3)
          echo "Displaying sol.json as a table..."
            echo "Select a solution file from solutions/ directory:"
            select sol_file in solutions/*.json; do
                if [[ -n "$sol_file" ]]; then
                    echo "Selected solution file: $sol_file"
                    break
                fi
            done
            
            if [[ -f "$sol_file" ]]; then
            echo "$sol_file"
            echo "============================================================================================================================"
                jq -r '["route_section_id", "route", "entry_time", "exit_time", "route_path", "sequence_number", "section_requirement"],(.zugfahrten[].zugfahrtabschnitte[] | [ .fahrwegabschnittId, .fahrweg, .ein, .aus, .abschnittsfolge, .reihenfolge, .abschnittsvorgabe // "---" ]) | @tsv' "$sol_file" | column -t -s$'	'
            echo "============================================================================================================================"
            else
                echo "sol.json not found. Run the solver first."
            fi
            ;;
         4)
          echo "Select files for comparison:"
          echo "File 1:"
          select sol_file1 in solutions/*.json; do
            if [[ -n "$sol_file1" ]]; then
                echo "Selected solution file: $sol_file1"
                break
            fi
          done

          select sol_file2 in solutions/*.json; do
            if [[ -n "$sol_file2" ]]; then
                echo "Selected solution file: $sol_file2"
                break
            fi
          done
        
          if [[ -f "$sol_file1" ]]; then
            echo "$sol_file1"
            echo "============================================================================================================================"
            jq -r '["route_section_id", "route", "entry_time", "exit_time", "route_path", "sequence_number", "section_requirement"],(.zugfahrten[].zugfahrtabschnitte[] | [ .fahrwegabschnittId, .fahrweg, .ein, .aus, .abschnittsfolge, .reihenfolge, .abschnittsvorgabe // "---" ]) | @tsv' "$sol_file1" | column -t -s$'	'
            echo "============================================================================================================================"
          else
            echo "sol.json not found. Run the solver first."
          fi

            echo "$sol_file2"
          if [[ -f "$sol_file2" ]]; then
            echo "============================================================================================================================"
            jq -r '["route_section_id", "route", "entry_time", "exit_time", "route_path", "sequence_number", "section_requirement"],(.zugfahrten[].zugfahrtabschnitte[] | [ .fahrwegabschnittId, .fahrweg, .ein, .aus, .abschnittsfolge, .reihenfolge, .abschnittsvorgabe // "---" ]) | @tsv' "$sol_file1" | column -t -s$'	'
            echo "============================================================================================================================"
          else
            echo "sol.json not found. Run the solver first."
          fi
          ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, or 0."
            ;;
    esac
    read -p "Press Enter to continue..."
done
