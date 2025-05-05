import sys
import json
import networkx as nx
from networkx.drawing.nx_agraph import write_dot, graphviz_layout
import time
import pathlib
import tempfile
import matplotlib.pyplot as plt


def from_node_id(route_path, route_section, index_in_path):
    if "vonVerzweigungen" in route_section.keys() and \
            route_section["vonVerzweigungen"] is not None and \
            len(route_section["vonVerzweigungen"]) > 0:
                return "(" + str(route_section["vonVerzweigungen"][0]) + ")"
    else:
        if index_in_path == 0:  # can only get here if this node is a very beginning of a route
            return "(" + str(route_section["reihenfolge"]) + "_beginning)"
        else:
            return "(" + (str(route_path["fahrwegabschnitte"][index_in_path - 1]["reihenfolge"]) + "->" +
                          str(route_section["reihenfolge"])) + ")"


def to_node_id(route_path, route_section, index_in_path):
    if "nachVerzweigungen" in route_section.keys() and \
            route_section["nachVerzweigungen"] is not None and \
            len(route_section["nachVerzweigungen"]) > 0:

                return "(" + str(route_section["nachVerzweigungen"][0]) + ")"
    else:
        if index_in_path == (len(route_path["fahrwegabschnitte"]) - 1): # meaning this node is a very end of a route
            return "(" + str(route_section["reihenfolge"]) + "_end" + ")"
        else:
            return "(" + (str(route_section["reihenfolge"]) + "->" +
                          str(route_path["fahrwegabschnitte"][index_in_path + 1]["reihenfolge"])) + ")"

def generate_route_graphs(scenario):
    start_time = time.time()

    # now build the graph. Nodes are called "previous_FAB -> next_FAB" within lineare abschnittsfolgen and "AK" if
    # there is an Abschnittskennzeichen 'AK' on it
    route_graphs = dict()
    for route in scenario["fahrwege"]:

        # set global graph settings
        G = nx.DiGraph(route_id = route["id"], name="Route-Graph for route "+str(route["id"]))

        # add edges with data contained in the preprocessed graph
        for path in route["abschnittsfolgen"]:
            for (i, route_section) in enumerate(path["fahrwegabschnitte"]):
                sn = route_section['reihenfolge']
                print("Adding Edge from {} to {} with sequence number {}".format(from_node_id(path, route_section, i), to_node_id(path, route_section, i), sn))
                G.add_edge(from_node_id(path, route_section, i),
                           to_node_id(path, route_section, i),
                           reihenfolge=sn)

        route_graphs[route["id"]] = G

    print("Finished building fahrweg-graphen in {} seconds".format(str(time.time() - start_time)))
    return route_graphs


def save_graph(route_graphs):
    for k, route_graph in route_graphs.items():
        for node in route_graph.nodes():
            route_graph.nodes[node]['label'] = node

        edge_labels = {}
        for node1, node2, data in route_graph.edges(data=True):
            edge_labels[(node1, node2)] = data['reihenfolge'] 

        for edge in route_graph.edges():
            route_graph.edges[edge]['label'] = edge_labels[edge]

        pos = nx.spring_layout(route_graph)
        nx.draw(route_graph, pos, edge_color='black', width=1, linewidths=1, node_size=500, node_color='pink', alpha=0.9)
        nx.draw_networkx_edge_labels(route_graph,pos,edge_labels=edge_labels,font_color='red')
        nx.write_graphml(route_graph, "graph-"+str(k)+".graphml")
        plt.show()

# scratch######################################

if __name__ == "__main__":
    scenario = sys.argv[1]
    with open(scenario) as fp:
        scenario = json.load(fp)
    route_graphs = generate_route_graphs(scenario)
    save_graph(route_graphs)