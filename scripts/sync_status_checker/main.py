#!/usr/bin/python3

import json
import requests
import argparse


# Define the JSON-RPC request payload
payload = {
    "jsonrpc": "2.0",
    "method": "eth_syncing",
    "params": [],
    "id": 1
}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Sync Status Checker for Ethereum Node")
    parser.add_argument("--rpc_endpoint", type=str, help="Ethereum RPC endpoint")

    args = parser.parse_args()

    # Send the request
    try:
        response = requests.post(args.rpc_endpoint, json=payload)
        response.raise_for_status()  # Raise error if request fails
        result = response.json()
        
        print(json.dumps(result, indent=4))  # Pretty-print sync details
    except requests.exceptions.RequestException as e:
        print(f"RPC request failed: {e}")
