#!/bin/bash

# Array to store settings and priorities
declare -A SETTINGS
declare -A PRIORITIES

# Default priorities
PRIORITIES[BUFFER_DELAY]=0
PRIORITIES[CONNECTION_WINDOW]=0
PRIORITIES[RESOURCE_SETTING]=0
PRIORITIES[TRANSITION]=0

# Function to display the menu
display_menu() {
    clear
    echo "===== Menu ====="
    
    # Display current optimization settings with priorities only if they are set
    echo "Optimizations:"
    
    if [[ -n "${SETTINGS[BUFFER_DELAY]}" ]]; then
        echo "1. Delay Buffer (Current: ${SETTINGS[BUFFER_DELAY]} seconds, Priority: ${PRIORITIES[BUFFER_DELAY]})"
    else
        echo "1. Delay Buffer"
    fi
    
    if [[ -n "${SETTINGS[CONNECTION_WINDOW]}" ]]; then
        echo "2. Connection Window (Current: ${SETTINGS[CONNECTION_WINDOW]} seconds, Priority: ${PRIORITIES[CONNECTION_WINDOW]})"
    else
        echo "2. Connection Window"
    fi
    
    if [[ -n "${SETTINGS[TRANSITION]}" ]]; then
        echo "3. Release Time (Current: ${SETTINGS[TRANSITION]}, Priority: ${PRIORITIES[TRANSITION]})"
    else
        echo "3. Release Time"
    fi

    if [[ -n "${SETTINGS[RESOURCE_SETTING]}" ]]; then
        echo "4. Resources (Current: ${SETTINGS[RESOURCE_SETTING]}, Priority: ${PRIORITIES[RESOURCE_SETTING]})"
    else
        echo "4. Resources"
    fi
    
    
    echo "5. Print Current Settings"
    echo ""
    
    echo "Solver:"
    echo "6. Set Priorities"
    echo "7. Run Solver"
    echo "8. See Solutions"
    echo "9. See Diff"
    echo ""
    echo "0. Exit"
    echo "================"
    
    # Ask for the user's menu choice
    read -p "Select an option: " choice

    case $choice in
        1) 
            read -p "Enter buffer delay (seconds): " buffer_delay
            SETTINGS[BUFFER_DELAY]=$buffer_delay
            echo "Buffer delay set to $buffer_delay seconds."
            read -p "Press Enter to return to the main menu..."
            ;;
        2) 
            read -p "Enter connection time window increase (seconds): " connection_window
            SETTINGS[CONNECTION_WINDOW]=$connection_window
            echo "Connection time window increased by $connection_window seconds."
            read -p "Press Enter to return to the main menu..."
            ;;
        3) 
            read -p "Enter Release Time buffer (seconds): " transition
            SETTINGS[TRANSITION]=$transition
            echo "Release Time buffer set to $transition."
            read -p "Press Enter to return to the main menu..."
            ;;
        4) 
            read -p "Maximize or Minimize resources? (maximize/minimize): " resource_choice
            SETTINGS[RESOURCE_SETTING]=$resource_choice
            echo "Resource setting set to $resource_choice."
            read -p "Press Enter to return to the main menu..."
            ;;
        5)
            echo "Current Settings:"
            for key in "${!SETTINGS[@]}"; do
                echo "$key: ${SETTINGS[$key]}, Priority: ${PRIORITIES[$key]}"
            done
            read -p "Press Enter to return to the main menu..."
            ;;
        6) 
            echo "Set Priorities:"
            echo "1. Delay Buffer"
            echo "2. Connection Window"
            echo "3. Release Time"
            echo "4. Resources"
            read -p "Assign priority for Delay Buffer (1-4): " dp_priority
            read -p "Assign priority for Connection Window (1-4): " cw_priority
            read -p "Assign priority for Release Time (1-4): " ti_priority
            read -p "Assign priority for Resources (1-4): " nr_priority
            PRIORITIES[BUFFER_DELAY]=$dp_priority
            PRIORITIES[CONNECTION_WINDOW]=$cw_priority
            PRIORITIES[TRANSITION]=$ti_priority
            PRIORITIES[RESOURCE_SETTING]=$nr_priority
            echo "Priorities set:"
            echo "Delay Buffer: ${PRIORITIES[BUFFER_DELAY]}"
            echo "Connection Window: ${PRIORITIES[CONNECTION_WINDOW]}"
            echo "Release Time: ${PRIORITIES[TRANSITION]}"
            echo "Resources: ${PRIORITIES[RESOURCE_SETTING]}"
            read -p "Press Enter to return to the main menu..."
            ;;
        7) 
            # Run Solver
            echo "Running solver..."
            run_solver
            read -p "Press Enter to return to the main menu..."
            ;;
        8) 
            # See Solutions
            see_solutions
            read -p "Press Enter to return to the main menu..."
            ;;
        9) 
            # See diff in solution
            see_diff
            read -p "Press Enter to return to the main menu..."
            ;;

        0) exit 0 ;; 
        *) echo "Invalid option!" ; sleep 1 ;;
    esac
    display_menu
}

# Function to run the solver
run_solver() {

   

    # Get values from SETTINGS and PRIORITIES arrays
    buffer_delay="${SETTINGS[BUFFER_DELAY]}"
    connection_window="${SETTINGS[CONNECTION_WINDOW]}"
    train_interval="${SETTINGS[TRANSITION]}"
    resource_setting="${SETTINGS[RESOURCE_SETTING]}"
    dp_priority="${PRIORITIES[BUFFER_DELAY]}"
    cw_priority="${PRIORITIES[CONNECTION_WINDOW]}"
    ti_priority="${PRIORITIES[TRANSITION]}"
    nr_priority="${PRIORITIES[RESOURCE_SETTING]}"

    # Clear the file before writing new content
    > encodings/encoding/robustness.lp

    # Only write the line if buffer_delay is set
if [[ -n "$buffer_delay" ]]; then
    echo "slack(${buffer_delay}000)." >> encodings/encoding/robustness.lp
    echo "#maximize{S/1000@${dp_priority},T,N,M: robust_travel_time(T,N,M,S)}." >> encodings/encoding/robustness.lp
fi

# Only write the line if connection_window is set
if [[ -n "$connection_window" ]]; then
    echo "window(${connection_window}000)." >> encodings/encoding/robustness.lp
    echo "#maximize{Win/1000@${cw_priority}, SI,ID,SI',ID': timed_connection(SI,ID,SI',ID',Min,Max,From,To,Win)}." >> encodings/encoding/robustness.lp
fi

# Only write the line if train_interval is set
if [[ -n "$train_interval" ]]; then
    echo "transition_slack(${train_interval}000)." >> encodings/encoding/robustness.lp
    echo "#maximize{TS/1000@${ti_priority},T,V',T',U,B: robust_transition(T,V',T',U,B,TS)}." >> encodings/encoding/robustness.lp 
fi

# Only write the line if resource_setting is set
if [[ -n "$resource_setting" ]]; then
    echo "resource_count(Count) :- Count = #count { R : enter_resource_chunk(T,R,C,V) }." >> encodings/encoding/robustness.lp
    echo "#${resource_setting} { Count@${nr_priority} : resource_count(Count) }." >> encodings/encoding/robustness.lp

    
fi

 #Ask user if we are running one instance or the whole suite
    echo "1. Run single instance"
    echo "2. Run SBB suite"
    read -p "Enter choice: " run_config

    case $run_config in
        1) 
            echo "Select a JSON instance file from the 'instances/' folder:"
            select instance_file in instances/*.json; do
                if [[ -f "$instance_file" ]]; then
                    instance_file_name="$(basename "$instance_file")"
                    echo "Selected instance file: $instance_file_name"
                    run_instance "$instance_file"
                    break
                else
                    echo "No valid instance file selected. Please choose a valid file."
                fi
            done
            ;;
        
        2)
            echo "Running instances p1-p9..."
            for i in {1..9}; do
                file="instances/p${i}.json"
                if [[ -f "$file" ]]; then
                    run_instance "$file"
                else
                    echo "Skipping missing file: $file"
                fi
            done
            ;;
    esac

}


run_instance() {
    local instance_file="$1"
    local instance_file_name
    instance_file_name="$(basename "$instance_file")"

    # Start generating the solution name based on the settings
    local solution_name="${instance_file_name%.*}"

    # Append buffer-related values if set
    if [[ -n "$buffer_delay" && -n "$dp_priority" ]]; then
        solution_name="${solution_name}_BDELAY-${buffer_delay}-PRIO-${dp_priority}"
    fi

    # Append connection window-related values if set
    if [[ -n "$connection_window" && -n "$cw_priority" ]]; then
        solution_name="${solution_name}_CONNECTION-${connection_window}-PRIO-${cw_priority}"
    fi

    # Append Release Time -related values if set
    if [[ -n "$train_interval" && -n "$ti_priority" ]]; then
        solution_name="${solution_name}_INTERVAL-${train_interval}-PRIO-${ti_priority}"
    fi

    # Append resource-related values if set
    if [[ -n "$resource_setting" && -n "$nr_priority" ]]; then
        solution_name="${solution_name}_SEGMENTS-${resource_setting}-rp-${nr_priority}"
    fi

    echo "Generated solution name: $solution_name"
    echo "Running solver..."
    ./solve_and_check.sh "$instance_file" "$solution_name"

    if [[ ! -f "sol" ]]; then
        echo "File not found!"
        exit 1
    fi



    awk 'BEGIN {found=0} 
        /[A-Z]/ && /^[A-Z ]+$/ { found=1 } 
        found' "sol" > "solutions/${solution_name}_DATA.txt"

    if [[ "$instance_file_name" != "$solution_name" ]]; then
        python3 metricdiff.py "solutions/${instance_file_name%.*}_DATA.txt" "solutions/${solution_name}_DATA.txt" >> "solutions/${solution_name}_DATA.txt"
    fi

    echo "Running validator..."
    python3 validator.py "solutions/${solution_name}.json" "$instance_file" >> "solutions/${solution_name}_DATA.txt"
}

# Function to see solutions
see_solutions() {
    # List files in the solutions directory
    echo "Select a solution file from the 'solutions' folder:"
    select sol_file in solutions/*.json; do
        if [[ -f "$sol_file" ]]; then
            echo "$sol_file"
            echo "============================================================================================================================"
            jq -r '["route_section_id", "route", "entry_time", "exit_time", "route_path", "sequence_number", "section_requirement"],(.zugfahrten[].zugfahrtabschnitte[] | [ .fahrwegabschnittId, .fahrweg, .ein, .aus, .abschnittsfolge, .reihenfolge, .abschnittsvorgabe // "---" ]) | @tsv' "$sol_file" | column -t -s$'\t'
            echo "============================================================================================================================"
            break
        else
            echo "No solution file found. Please make sure you run the solver first."
            break
        fi
    done
}

# Function to see diff between solution and baseline

see_diff() {
    # List files in the solutions directory
    echo "Select a solution file from the 'solutions' folder:"
    select sol_file in solutions/*.json; do
        if [[ -f "$sol_file" ]]; then
            echo "$sol_file"
            echo "${sol_file%_*}.json"
            diff --color=always --side-by-side --suppress-common-lines <(jq -S . "${sol_file%_*}.json") <(jq -S . "$sol_file")
            break
        else
            echo "No solution file found. Please make sure you run the solver first."
            break
        fi
    done 
}





# Start the script
display_menu
