import yaml
import kcidb_io

with open("submission.yaml", "r") as f:
    submission = yaml.safe_load(f)

kcidb_io.schema.V5_3().validate(submission)
