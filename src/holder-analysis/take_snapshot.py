#!/usr/bin/env python
from dotenv import load_dotenv
import requests
import json
import os

load_dotenv()


def get_all_holders():

    holders = []
    skip = -1000
    query_result = [""]
    query = (
        lambda skip: """query {
        owners(first: 1000, skip: """
        + str(int(skip))
        + """) {
            id
            numKongsOwned
        }
    }"""
    )

    def get_batch():
        nonlocal holders, skip, query_result

        skip += 1000

        r = requests.post(os.environ["SUBGRAPH_URI"], json={"query": query(skip)})
        if r.status_code != 200:
            # if you write a shell script to restart this script, this error
            # will be useful
            raise Exception(
                "There was a problem with the request. Waiting and re-running."
            )
        query_result = r.json()["data"]["owners"]
        if len(query_result) > 0:
            holders.extend(query_result)

    # * while there are responses from the subgraph get batch
    while len(query_result) > 0:
        get_batch()

    return holders


def main():
    holders = get_all_holders()
    with open("snapshot.json", "w") as f:
        f.write(json.dumps(holders, indent=4))


if __name__ == '__main__':
    main()
