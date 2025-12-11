#####agent with memory 

import streamlit as st
from langchain_community.chat_message_histories import ChatMessageHistory
from langchain_core.prompts import PromptTemplate
from langchain_ollama import OllamaLLM
 
llm=OllamaLLM(model='phi')
if "chat_history" not in st.session_state:
    st.session_state.chat_history=ChatMessageHistory()


prompt=PromptTemplate(
    input_variables=["chat_history","question"],
    template="Previous conversation:{chat_history} \n User: {question}\n AI:"
)

def run_chain(question):
    chat_historytxt="\n".join([f"{msg.type.capitalize()}: {msg.content})" for msg in st.session_state.chat_history.messages])
    response=llm.invoke(prompt.format(chat_history=chat_historytxt,question=question))
    st.session_state.chat_history.add_user_message(question)
    st.session_state.chat_history.add_ai_message(response)
    return response

#strealm lit UI
    
st.title("AI chatbot with memoy ")
st.write("Ask me anything")

user_input=st.text_input("your question")
if user_input:
    response=run_chain(user_input)
    st.write(f"you: {user_input}")
    st.write(f"Ai: {response}")

    #show full chat history
st.subheader("chat history ")
for msg in st.session_state.chat_history.messages:
    st.write(f"** {msg.type.capitalize()}**:{msg.content}")








# from langchain_community.chat_message_histories import ChatMessageHistory
# from langchain_core.prompts import PromptTemplate
# from langchain_ollama import OllamaLLM


# llm=OllamaLLM(model="mistral")
# #initialize memory 
# chat_history= ChatMessageHistory() # stores the conversTION 
# #Define Ai chat prompt 
# prompt=PromptTemplate(
#     input_variables=["chat_history","question"],
#     template="Previous conversatiin: {chat_history} \n User: {question}\nAI:"
# )

# #function for ai chat

# def run_chain(question):
#     #retrieve chat history manually
#     chat_history_test="\n".join([f"{msg.type.capitalize()}:{msg.content}" for msg in chat_history.messages])
#     ressponse=llm.invoke(prompt.format(chat_history=chat_history_test,question=question))
#     chat_history.add_user_message(question)
#     chat_history.add_ai_message(ressponse)
#     return ressponse

# print("\n Ai agent with memory")
# while True:
#     user_input=input("Your Question: ") 
#     if user_input.lower()=='exit':
#         print("goodbye")
#         break
#     ai_response=run_chain(user_input)
#     print(f"\n AI answer {ai_response}")



###ai agent


# from langchain_ollama import OllamaLLM

# #load Ai model from ollama

# llm=OllamaLLM(model="mistral")


# print("\n welcome to AI agent! ask me anything.")
# while True:
#     question=input("Your Question: ") 
#     if question.lower()=='exit':
#         print("goodbye")
#         break
#     response=llm.invoke(question)
#     print(f"\n AI answer {response}")