import json
import boto3
import pymsteams
from os import environ
from botocore.vendored import requests


class PipelineData:
    def __init__(self, build_status, project_name, build_arn, build_start_time, pipeline_logs_url):
        self.build_passed = False
        self.project_name = project_name
        self.build_arn = build_arn
        self.build_start_time = build_start_time
        self.pipeline_logs_url = pipeline_logs_url
        if build_status == 'SUCCEEDED':
            self.build_passed = True


def construct_ms_teams_message(BuildPipelineObj, teams_url):
    build_status = "failed"
    image_url = "https://upload.wikimedia.org/wikipedia/en/thumb/f/ff/SuccessKid.jpg/256px-SuccessKid.jpg"
    activity_title = "Build Failed"

    if BuildPipelineObj.build_passed == True:
        build_status = "succeeded"
        activity_title = "Build Succeeded"
        image_url = "https://www.dictionary.com/e/wp-content/uploads/2018/03/thisisfine-1.jpg"

    ms_Teams_Message = pymsteams.connectorcard(teams_url)
    ms_Message_Section = pymsteams.cardsection()

    ms_Message_Section.activityTitle(activity_title)
    ms_Message_Section.activityImage(image_url)
    ms_Teams_Message.addSection(ms_Message_Section)
    ms_Teams_Message.text("Build " + BuildPipelineObj.project_name + " has " + build_status + "\n" +
                          "Build ARN: " + BuildPipelineObj.build_arn + "\n" +
                          "Start Time: " + BuildPipelineObj.build_start_time + "\n" +
                          "Logs URL: " + BuildPipelineObj.pipeline_logs_url
                          )

    return ms_Teams_Message


def get_pipeline_data(lambda_event):
    sns_message = lambda_event['Records'][0]['Sns']['Message']
    json_message = json.loads(sns_message)
    build_status = json_message['detail']['build-status']
    project_name = json_message['detail']['project-name']
    build_arn = json_message['detail']['build-id']
    build_start_time = json_message['detail']['additional-information']['build-start-time']
    pipeline_logs_url = json_message['detail']['additional-information']['logs']['deep-link']

    BuildPipeline = PipelineData(
        build_status, project_name, build_arn, build_start_time, pipeline_logs_url)

    return BuildPipeline


def lambda_handler(event, context):
    teams_url = environ.get('TEAMS_URL')
    BuildPipelineObj = get_pipeline_data(event)
    msTeamsMessage = construct_ms_teams_message(BuildPipelineObj, teams_url)
    msTeamsMessage.send()
