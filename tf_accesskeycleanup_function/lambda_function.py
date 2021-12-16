import boto3
import datetime
import dateutil.tz

print('Loading function')

resource_iam = boto3.resource('iam')
client_iam = boto3.client("iam")

def lambda_handler(event, context):
    ninety_days_ago = datetime.datetime.now() - datetime.timedelta(days=90)

    for user in resource_iam.users.all():
        list_keys_metadata = client_iam.list_access_keys(UserName=user.user_name)
        if list_keys_metadata['AccessKeyMetadata']:
            for key in user.access_keys.all():
                access_key_id=key.access_key_id
                last_used = client_iam.get_access_key_last_used(AccessKeyId=access_key_id)
                if (key.status == "Active"):
                    if 'LastUsedDate' in last_used['AccessKeyLastUsed']:
                        if last_used['AccessKeyLastUsed']['LastUsedDate'].replace(tzinfo=dateutil.tz.UTC) > ninety_days_ago.replace(tzinfo=dateutil.tz.UTC):
                            print("INFO:", user.user_name , ":", access_key_id , "was used in the last 90 days. Last used on" , str(last_used['AccessKeyLastUsed']['LastUsedDate']))
                        else:
                            print("INFO:", user.user_name , ":", access_key_id , "was NOT used in the last 90 days. Last used on" , str(last_used['AccessKeyLastUsed']['LastUsedDate']))
                            client_iam.delete_access_key(AccessKeyId=access_key_id,UserName=user.user_name)
                            print("INFO:", user.user_name , ":", access_key_id , "has been deleted")
                    else:
                        print("INFO:", user.user_name , ":", access_key_id , "is Active but has never been used")
                else:
                    print ("INFO:", user.user_name , ":", access_key_id , "is InActive")
        else:
            print ("INFO:", user.user_name , "has no keys associated with the user")
 
    response = ""
