import json
import networkx as nx
import matplotlib.pyplot as plt

# Load p1.json file
p1_path = 'instances/p1.json'
with open(p1_path, 'r') as file:
    print ("THIS IS FILEE!!!!!!")
    print(file)
    p1_data = json.load(file)

# Parse the network graph structure from fahrwege
graph = nx.DiGraph()

# Iterate over all routes (fahrwege)
for route in p1_data['fahrwege']:
    for section in route['abschnittsfolgen']:
        for connection in section['fahrwegabschnitte']:
            start = connection['startpunkt']
            end = connection['endpunkt']
            graph.add_edge(start, end)

# Visualize the base network
plt.figure(figsize=(12, 8))
pos = nx.spring_layout(graph)  # Layout for better visualization
nx.draw_networkx_nodes(graph, pos, node_size=500, node_color='lightblue')
nx.draw_networkx_edges(graph, pos, arrowstyle='->', arrowsize=10, edge_color='gray')
nx.draw_networkx_labels(graph, pos, font_size=10, font_color='black')
plt.title("Base Rail Network from p1.json", fontsize=16)
plt.show()
