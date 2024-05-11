#!/usr/bin/env python

from influxdb_client.client.write_api import SYNCHRONOUS
from flask import Flask
from waitress import serve
import yaml
import subprocess
import logging
import jq
import json
import os
import influxdb_client

app = Flask(__name__)

def read_config():
    global logger
    global config
    global db
    logger = logging.Logger(name="sys-stats", level=logging.DEBUG)
    logger.addHandler(logging.StreamHandler())
    with open("config.yml", mode="r") as file:
        config_text = file.read()
        config_text = os.path.expandvars(config_text)
        config = yaml.safe_load(config_text)
        logger.info("Configurations loaded successfully!!")
    db = initialize_influx()

def initialize_influx():
    try:
        influx_config = config["influx"]
        influx_client = influxdb_client.InfluxDBClient(
            url=influx_config["url"], token=influx_config["token"], org=influx_config["org"]
        )
        if influx_client.ready().status!='ready':
            raise Exception("Couldn't connect to influx DB")
        return influx_client.write_api(write_options=SYNCHRONOUS)
    except Exception as e:
        raise Exception("Failed to initialize the influx DB", e)

def process_point(stat):
    temp = []
    for point in stat["points"]:
        point_response = {}
        logger.info("\tProcessing point command : " + str(point["command"]))
        res = subprocess.run(point["command"], capture_output=True, text= True)
        if res.stderr:
            logger.error("\tError : " + res.stderr)
        res_json = json.loads(res.stdout)
        tags = process_tags(point)
        point_response["tags"] = tags
        fields = process_fields(point, res_json)
        point_response["fields"] = fields
        push_to_influx(point, point_response)
        temp.append(point_response)
    return temp

def push_to_influx(point, res):
    influx_config = config["influx"]
    
    record = influxdb_client.Point(point["measurement"])
    for k,v in res["tags"].items():
        record.tag(k, v)
    for k,v in res["fields"].items():
        record.field(k,v)

    db.write(bucket=influx_config["bucket"], org=influx_config["org"], record=record)

def process_tags(point):
    tags = {}
    for tag in point["tags"]:
        tags[tag["key"]]=tag["value"]
    return tags

def process_fields(point, response):
    fields = {}
    for field in point["fields"]:
        val = jq.compile(field["value"]).input_value(response).text()
        val = float(val) if val != "null" else 0
        fields[field["key"]] = val
    return fields

@app.route("/execute", methods=["GET"])
def execute():
    logger.info("-"*100)
    response = {}
    for stat in config["stats"]:
        logger.info("Processing stat for : " + stat["name"])
        point_res = process_point(stat)
        response[stat["name"]] = point_res
    logger.info("-"*100)
    return response

@app.route("/", methods=["GET"])
def ping():
    return "pong"

if __name__=="__main__":
    read_config()
    # response = execute()
    # logger.info(json.dumps(response, indent=2))
    serve(app, port=2543)

