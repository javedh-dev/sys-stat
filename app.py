#!/usr/bin/env python

from flask import Flask
from waitress import serve
import yaml
import subprocess
import logging
import jq
import json
import os

app = Flask(__name__)

def read_config():
    global logger
    global config
    logger = logging.Logger(name="sys-stats", level=logging.DEBUG)
    logger.addHandler(logging.StreamHandler())
    with open("config.yml", mode="r") as file:
        config_text = file.read()
        config_text = os.path.expandvars(config_text)
        config = yaml.safe_load(config_text)
        logger.info("Configurations loaded successfully!!")

def execute():
    response = {}
    for stat in config:
        logger.info("Processing stat for : " + stat["name"])
        point_res = process_point(stat)
        response[stat["name"]] = point_res
    return response

def process_point(stat):
    temp = []
    for point in stat["points"]:
        point_response = {}
        logger.info("\tProcessing point command : " + str(point["command"]))
        res = subprocess.run(point["command"], capture_output=True, text= True)
        res_json = json.loads(res.stdout)
        tags = process_tags(point)
        point_response["tags"] = tags
        fields = process_fields(point, res_json)
        point_response["fields"] = fields
        temp.append(point_response)
    return temp

def process_tags(point):
    tags = []
    for tag in point["tags"]:
        tags.append({tag["key"] : tag["value"] })
    return tags

def process_fields(point, response):
    fields = []
    for field in point["fields"]:
        d = jq.compile(field["value"]).input_value(response).text()
        val = d if d else 0
        fields.append({field["key"]: val})
    return fields

@app.route("/", methods=["GET"])
def ping():
    return "pong"

if __name__=="__main__":
    read_config()
    response = execute()
    logger.info(json.dumps(response, indent=2))
    # serve(app, port=2543)

