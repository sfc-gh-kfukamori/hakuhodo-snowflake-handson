import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.title("動作テスト")
st.write("Hello from Streamlit in Snowflake!")

result = session.sql("SELECT CURRENT_TIMESTAMP() AS NOW").collect()
st.write(f"現在時刻: {result[0]['NOW']}")
