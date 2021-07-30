import os
from slack import WebClient

client = WebClient(token=os.environ["2985839111-1935337628596-Tm3EiBmJ9dwkJDOceINprQwL"])
response = client.conversations_info(
  channel="C031415926",
  include_num_members=1
)