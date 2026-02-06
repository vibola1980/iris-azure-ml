#!/usr/bin/env python3
"""
Train a real scikit-learn model on the Iris dataset and save with joblib
"""
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import joblib
import os


def main():
    data = load_iris()
    X, y = data.data, data.target
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)

    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)
    print(f"Test accuracy: {acc:.4f}")

    os.makedirs('models', exist_ok=True)
    joblib.dump(model, 'models/model.pkl')
    print('Saved model to models/model.pkl')


if __name__ == '__main__':
    main()
