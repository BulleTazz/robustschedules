import json

from typing import List, Any, Dict, Tuple, Optional
from model.business import TimeReference

def convert_json_to_asp(json_data):
    facts = []
    for item in json_data["funktionaleAngebotsbeschreibungen"]:
        facts.append(f"json_si({item['id']}).")
        for v in item.get("abschnittsvorgaben", []):
            facts.append(f"json_abschnittVorgabe({item['id']}, {v['reihenfolge']}, \"{v['abschnittskennzeichen']}\", \"{v['typ']}\", \"{v.get('einMin', '')}\").")
    for resource in json_data["ressourcen"]:
        facts.append(f"json_ressourcenbelegung(\"{resource['id']}\", \"{resource['freigabezeit']}\", {str(resource['zugfolgeErlaubt']).lower()}).")
    return "\n".join(facts)


def convert_string_to_datetime(datetime_string: Optional[str]):
    return TimeReference.safe_parse_timestamp(datetime_string)


def convert_strings_to_datetimes(vp_dict: Dict[str, Any]) -> Dict[str, Any]:
    for fa in vp_dict['funktionaleAngebotsbeschreibungen']:
        for av in fa['abschnittsvorgaben']:
            for key in ('einMin', 'einMax', 'ausMin', 'ausMax'):
                av[key] = convert_string_to_datetime(av.get(key, None))

    return vp_dict


with open("p1.json") as f:
    data = json.load(f)
asp_output = convert_json_to_asp(data)

with open("p1_test.lp", "w") as f:
    f.write(asp_output)


