def code_completion_demo(prompt):
    payload = {
        "messages": [
            {"role": "system", "content": "You are a helpful coding assistant."},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.3,  # Lower temperature for code generation
        "max_tokens": 1000
    }
    # Add API call implementation 