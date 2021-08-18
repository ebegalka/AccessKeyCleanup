# AccessKeyCleanup

Requirement:
Design a Lambda function and account for the supporting AWS resources to regularly check for and delete all IAM keys which have not been used in 90 days. Submit the design as a self-contained set of infrastructure-as-code. Either terraform or cloudformation is acceptable.

Notes:
Overview of the architecture is that there is a lambda python function which pulls the list of users, looks at their access keys, and if they have been without use for 90 days, they are deleted. I also added monitoring capability to the function so the user can see all the logs via cloudwatch.

Disclaimer:
One important note is that this, because it is just a proof of concept, I would warn the user to be cautious with testing because the lambda runs every 5 minutes! If a user puts this anywhere other than a temporary test environment where they're just evaluating the code, they should delete/modify the rule to be daily otherwise it will rack up costs. It was left as 5 minutes for the ease of testing, but in the real world it is suggested to make it run daily at ~midnight. 

Future Enhancements:
Abandon the daily clock entirely and just have it based around config rules
