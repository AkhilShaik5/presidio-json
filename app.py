from flask import Flask, request, render_template, jsonify
from presidio_analyzer import AnalyzerEngine
from presidio_anonymizer import AnonymizerEngine
from presidio_analyzer.nlp_engine import NlpEngineProvider
from typing import Dict, List
import os
import spacy

app = Flask(__name__)

# Configure NLP engine with medium model
configuration = {
    "nlp_engine_name": "spacy",
    "models": [{"lang_code": "en", "model_name": "en_core_web_md"}]
}
provider = NlpEngineProvider(nlp_configuration=configuration)
nlp_engine = provider.create_engine()

# Initialize the Presidio engines with the configured NLP engine
analyzer = AnalyzerEngine(nlp_engine=nlp_engine)
anonymizer = AnonymizerEngine()

def analyze_and_mask_text(text: str) -> Dict:
    # Analyze the text
    analyzer_results = analyzer.analyze(
        text=text,
        language='en',
        entities=['PERSON', 'EMAIL_ADDRESS', 'PHONE_NUMBER', 'CREDIT_CARD', 
                 'LOCATION', 'DATE_TIME', 'US_SSN', 'IP_ADDRESS']
    )
    
    # Anonymize the text with the analyzer's results
    anonymized_text = anonymizer.anonymize(
        text=text,
        analyzer_results=analyzer_results
    )

    return {
        'original_text': text,
        'anonymized_text': anonymized_text.text,
        'detected_entities': [
            {
                'entity_type': result.entity_type,
                'start': result.start,
                'end': result.end,
                'score': result.score
            } for result in analyzer_results
        ]
    }

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/mask', methods=['POST'])
def mask_text():
    if request.method == 'POST':
        data = request.json
        if not data or 'text' not in data:
            return jsonify({'error': 'No text provided'}), 400
        text = data['text']
        
        try:
            result = analyze_and_mask_text(text)
            return jsonify(result)
        except Exception as e:
            return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)