import json
import boto3
import pymsteams
from botocore.vendored import requests

def lambda_handler(event, context):
    teams_url = 'https://outlook.office.com/webhook/9d74251a-814f-45f1-8a1f-93763b9f2d4f@71ad2f62-61e2-44fc-9e85-86c2827f6de9/IncomingWebhook/7ce3e7ee70d94c82a09426fc3e6d4a0e/7b73812c-1043-4127-a655-17f0f183ee5d'
    msTeamsMessage = pymsteams.connectorcard(teams_url)
    msMessageSection = pymsteams.cardsection()
    msMessageSection.activityTitle("Build Failed")
    msMessageSection.activityImage("https://www.dictionary.com/e/wp-content/uploads/2018/03/thisisfine-1.jpg")
    msMessageSection.activityText("This is my activity Text")
    msTeamsMessage.addSection(msMessageSection)
    msTeamsMessage.text("The artifactory-test build has failed.")
    msTeamsMessage.send()
    print(event)
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
