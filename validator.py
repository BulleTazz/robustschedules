import json
import argparse
from datetime import datetime, timedelta
import re

def parse_time(t):
    if t is None:
        return None

    # Fix timezone format from +02:00 to +0200 if present
    if re.match(r".*[+-]\d{2}:\d{2}$", t):
        t = re.sub(r"([+-]\d{2}):(\d{2})$", r"\1\2", t)

    # Define possible formats
    formats = [
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%S.%f%z",
        "%Y-%m-%dT%H:%M:%S",
        "%H:%M:%S",
        "%H:%M:%S.%f",
        "%H:%M",
    ]
    
    for fmt in formats:
        try:
            parsed_time = datetime.strptime(t, fmt)
            return parsed_time.replace(microsecond=0)
        except ValueError:
            continue

    return None
    
# def parse_duration(dur):
#     """Parse a duration string into a timedelta object."""
#     try:
#         if dur is None:
#             return timedelta(0)
#         if dur.startswith("PT") and "M" in dur:
#             return timedelta(minutes=int(dur[2:-1]))
#         return timedelta(0)
#     except:
#         print("####################################")
#         print(dur)
#         print("####################################")

def parse_duration(dur):
    try:
        if dur is None:
            return timedelta(0)

        match = re.fullmatch(r"PT(?:(\d+)M)?(?:(\d+)S)?", dur)
        if not match:
            print(f"⚠️ Unsupported duration format: {dur}")
            return timedelta(0)

        minutes = int(match.group(1)) if match.group(1) else 0
        seconds = int(match.group(2)) if match.group(2) else 0
        return timedelta(minutes=minutes, seconds=seconds)
    except:
        print("####################################")
        print(dur)
        print("####################################")

def validate_schedule(solution, constraints):
    """Validate the schedule against the given constraints."""
    constraint_map = {}
    for angebot in constraints.get("funktionaleAngebotsbeschreibungen", []):
        zug_id = angebot.get("id")
        constraint_map[str(zug_id)] = {a["abschnittskennzeichen"]: a for a in angebot.get("abschnittsvorgaben", [])}

    print("Constraints loaded.")

    for zug in solution.get("zugfahrten", []):
        zug_id = zug.get("funktionaleAngebotsbeschreibungId")
        print(f"\n🚆 Checking Zug {zug_id}:")
        for abschnitt in zug.get("zugfahrtabschnitte", []):
            kennz = abschnitt.get("abschnittsvorgabe")  # Check if abschnittsvorgabe exists
            ein = parse_time(abschnitt.get("ein"))
            aus = parse_time(abschnitt.get("aus"))
            constraints_zug = constraint_map[zug_id]
            vorgabe = constraints_zug.get(kennz)

            if not vorgabe:
                if kennz : print(f" ⚠️ Abschnitt {kennz}: No constraints found.")
                continue

            passed = True
            einMin = parse_time(vorgabe.get("einMin"))
            einMax = parse_time(vorgabe.get("einMax"))
            ausMin = parse_time(vorgabe.get("ausMin"))
            ausMax = parse_time(vorgabe.get("ausMax"))
            minHaltezeit = parse_duration(vorgabe.get("minHaltezeit"))

            # Check time constraints only if times are valid
            if einMin and ein and ein < einMin:
                print(f" ❌ {kennz}: 'ein' {ein.time()} < 'einMin' {einMin.time()}")
                passed = False
            if einMax and ein and ein > einMax:
                print(f" ❌ {kennz}: 'ein' {ein.time()} > 'einMax' {einMax.time()}")
                passed = False
            if ausMin and aus and aus < ausMin:
                print(f" ❌ {kennz}: 'aus' {aus.time()} < 'ausMin' {ausMin.time()}")
                passed = False
            if ausMax and aus and aus > ausMax:
                print(f" ❌ {kennz}: 'aus' {aus.time()} > 'ausMax' {ausMax.time()}")
                passed = False
            if minHaltezeit and ein and aus:
                haltezeit = aus - ein
                if haltezeit < minHaltezeit:
                    print(f" ❌ {kennz}: Haltezeit {haltezeit} < minHaltezeit {minHaltezeit}")
                    passed = False
            if passed:
                print(f" ✅ Abschnitt {kennz}: OK")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Validate train schedule against constraints.")
    parser.add_argument("solution_file", help="Path to the solution file (e.g. solutions/example.json)")
    parser.add_argument("constraints_file", help="Path to the constraints file (e.g. instances/example.json)")
    
    args = parser.parse_args()
    
    with open(args.solution_file) as solf, open(args.constraints_file) as conf:
        solution_data = json.load(solf)
        constraints_data = json.load(conf)
        validate_schedule(solution_data, constraints_data)



        # ja que estamos a iterar sobre a solucao, podemos contar o numero de segmentos e validar o 'number of resources used'
        # fazer simulações consistentes, ver quais os parametros que nos dizem mais
        # Ver quais sao as limitacoes que temos (como por exemplo limite de tempo e memoria)
        # Fazer plano detalhado, (Estabelecer o que consigo escrever até a proxima reuniao)
        # 10/04 18:30 reuniao

