# LAX-Flight-Prediction

*Utilizing feature engineering and a suite of machine learning techniques to classify and predict flights as on-time or delayed*

If you have ever visited Google Flights and made a flight plan, you may have noticed that Google will warn you if a flight is frequently delayed. However, Google provides this warning on an aggregate basis using the flight number. This is not fully informative as it will not take into account patterns over time and other features about a specific flight that could impact the chances of an on-time arrival at destination. Using public data from the Bureau of Transportation Statistics, a model was trained to attempt to improve on this process in R. This initially began as a class project at UCLA with fellow students <a href = "https://www.linkedin.com/in/alexjkrebs/"> Alex Krebs </a> and <a href = "https://www.linkedin.com/in/echo-huanchen-wang-9b338577/"> Echo (Huanchen) Wang <a/>. 

Initial models used included GLM with logit, XGBoost, SVM, Random Forest, and a custom ensemble method. I intend to post a clean version the coding work we have done in the coming weeks. After that, there are several additional avenues I intend to pursue to improve upon our initial result, including:

1. Creating a feature that catalogs percentage of major delays by flight number (done, added to cleaned file)
2. Exploring if results improve by using testing data that is more recent in time to the training data
3. Including additional algorithms such as neural network
4. Exploring algorithms for prediction of exact delay/early times instead of classification and developing error bounds
5. Replicating the coding in Python for comparison of lines used/efficiency
6. Exploration of speed improvements using tensorFlow, expansion to many airports instead of just LAX
7. ???
8. Profit
