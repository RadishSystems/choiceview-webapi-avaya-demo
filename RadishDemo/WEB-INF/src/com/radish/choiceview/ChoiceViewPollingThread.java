/**
 * Date: 		Nov 13, 2009
 * File Name: 	ChoiceViewThread.java
 * Project Name:ShopNBC
 * $Id$
 */
package com.radish.choiceview;

/**
 * @author Derek Teuscher
 *
 */

import java.io.IOException;
import java.net.URI;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.radishsystems.choiceview.webapi.*;
import org.apache.log4j.*;

import org.apache.http.HttpEntity;
import org.apache.http.HttpHost;
import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.ParseException;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.AuthCache;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpDelete;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.protocol.ClientContext;
import org.apache.http.client.utils.URIBuilder;
import org.apache.http.entity.ContentType;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.auth.BasicScheme;
import org.apache.http.impl.client.BasicAuthCache;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.protocol.BasicHttpContext;
import org.apache.http.util.EntityUtils;
import org.codehaus.jackson.map.ObjectMapper;

public class ChoiceViewPollingThread implements Runnable{

	private Logger mylogger = null;
	
	private boolean stopRequested = false;
	
	private ChoiceViewSession cvs = null;
	private String sessionID = "";
	private String sessionURL = "";
	private String basicHttpID = "";
	private long pollInterval;

	/**
	 * 
	 */
	public ChoiceViewPollingThread(String sessionID, ChoiceViewSession cvs, String sessionURL, String basicHttpID, long pollInterval) {
	
		this.sessionID = sessionID;
		this.cvs = cvs;
		this.sessionURL = sessionURL;
		this.basicHttpID = basicHttpID;
		this.pollInterval = pollInterval;
	}


	/* (non-Javadoc)
	 * @see java.lang.Thread#run()
	 */
	@Override
	public void run() {
			
		mylogger.debug("Running new ChoiceView Polling Thread[" + this.sessionID + "]");
		mylogger.debug("ChoiceView hashCode[" + cvs.hashCode() + "]");
		
		mylogger.debug("CV State Change URI: " + this.sessionURL);
		mylogger.debug("CV Session ID: " + this.sessionID);
		mylogger.debug("CV Poll Interval: " + this.pollInterval);
		mylogger.debug("CCXML session ID: " + this.basicHttpID);
		
		boolean done = false;
		
		boolean sentConnected = false;
		
		while(!done){
			
			mylogger.debug("Checking CV Session[" + this.sessionID + "]");
			
	        try {       		
	        		
	        	if(cvs.updateSession() == false){

	        		throw new InterruptedException("Update session failed. Assuming disconnect.");
	        	}

	        	String status = cvs.getStatus();
	        	mylogger.debug("Status: " + status);
	        	
	        	if("disconnected".equalsIgnoreCase(status)){
	        		cvs.sendStateChangeEvent(URI.create(this.sessionURL), this.basicHttpID , "");
	        		throw new InterruptedException("Got newstate - Call was disconnected.");
	        	}
	        	
	        	if("connected".equalsIgnoreCase(status) && !sentConnected){
	        		sentConnected = true;
	        		cvs.sendStateChangeEvent(URI.create(this.sessionURL), this.basicHttpID , "");
	        		continue;
	        	}
	        	  
	        	 //Check the CV Session for a new event
	        	Map<String, String> controlMessageMap = cvs.getControlMessage();
	        	
	        	if(controlMessageMap == null){
	        		mylogger.debug("Map is null");
	        	}else{
	        		
	        		mylogger.debug(this.sessionID + ": We got a new control message in the CV Session.");
	        		
	        		//we got something, so notify the ccxml code
	        		Set<String> keySet = controlMessageMap.keySet();
	        		for(Iterator <String>it = keySet.iterator(); it.hasNext(); ){
	        			String key = it.next();
	        			mylogger.debug("ControlMessage Key: " + key + "value: "+ controlMessageMap.get(key));
	        		}
	        		
	        		mylogger.debug("Sending control message");
	           		cvs.sendControlMessageEvent(URI.create(this.sessionURL), this.basicHttpID, "", controlMessageMap);
	        	}
	        	
	        	Thread.sleep(pollInterval);
	        	 
	        } catch (InterruptedException e) {
	        	mylogger.info("Thread with sessionID: " + sessionID + " was interrupted. We are done.", e);
	        	done = true;
            } catch (Exception e) {
	           	mylogger.error("[" + this.sessionID + "] " + "Exception String: " + e.toString(), e); 
	           	done = true;
	        }//catch
       
		}//while
		
	    return;
	}//run

	private boolean sendDisconnectEvent(URI eventUrl, String sessionId, String eventSource) throws IOException{
		Map<String, String> parameters = new HashMap<String,String>();
		
		parameters.put("newstate", "disconnected");
		
		mylogger.info("Here1");
		return sendStateChangeMessage(eventUrl, sessionId, eventSource, parameters);
	}
	
	private static boolean eventSent(HttpResponse response) {
		int statusCode = response.getStatusLine().getStatusCode();
		return (statusCode == 204);
	}

	ResponseHandler<Boolean> eventHandler = new ResponseHandler<Boolean>() {
		public Boolean handleResponse(HttpResponse response) 
				throws ClientProtocolException, IOException {
			if(!eventSent(response)) {
				printErrorResponse(response);
				return false;
			}
			return true;
		}
	};

	private DefaultHttpClient eventProcessor = new DefaultHttpClient();
	private BasicHttpContext eventContext  = null;
	
	private static void printErrorResponse(HttpResponse response) {
		HttpEntity entity = response.getEntity();
		if (entity != null) {
			try {
				System.err.println(EntityUtils.toString(entity));
			}
			catch (ParseException e) {
				System.err.println("Cannot parse response: " + entity.getContentType().getValue());
			}
			catch (IOException e) {
				System.err.println("Cannot read response: " + e.getMessage());
			}
			finally {
				try {
					entity.getContent().close();
				} catch (Exception e) {
					System.err.println("Cannot close response content stream: " + e.getMessage());
				}
			}
		}
	}
	

	
	private boolean isNullOrEmpty(String s){
		if("".equals(s) || s == null){
			return true;
		}
		
		return false;
	}
	
	
	
/*
Session:uid_1:  #####Received Control Message Event#####
Session:uid_1:     eventdata... 
 [
 ButtonName:Visual_Response
 eventsourcetype:basichttp
 ButtonNumber:0
 MenuName:Main_Menu
 name:controlmessage
 MenuNumber:1
 ]
Session:uid_1:  name=controlmessage
Session:uid_1:  sourcetype=basichttp
Session:uid_1:  eventsource=undefined
Session:uid_1:  ButtonNumber=0
Session:uid_1:  MenuNumber=1
Session:uid_1:  MenuName=Main_Menu
Session:uid_1:  ButtonName=Visual_Response
*/
	
	private boolean sendControlMessage(URI eventUrl, String sessionId,  String eventSource,
			Map<String, String> parameters)throws IOException {
		return sendCCXMLEvent( eventUrl,  sessionId,  "controlmessage",  eventSource, parameters);
	}
   		 
			
/* 
	Session:uid_39:  #####Received State Change Event#####
	Session:uid_39:     eventdata... 
	 [
	 eventsourcetype:basichttp
	 name:statechange
	 newstate:disconnected
	 ]
	Session:uid_39:  name=statechange
	Session:uid_39:  newstate=disconnected
*/	
	
	private boolean sendStateChangeMessage(URI eventUrl, String sessionId, String eventSource,
			Map<String, String> parameters)throws IOException {
		mylogger.info("Here2");
		return sendCCXMLEvent( eventUrl,  sessionId,  "statechange",  eventSource, parameters);
	}

	
	
	public boolean sendCCXMLEvent(URI eventUrl, String sessionId, String eventName, String eventSource,
			Map<String, String> parameters) throws IOException {
		
		mylogger.info("Here3");
		if(isNullOrEmpty(sessionId) || isNullOrEmpty(eventName)) {
			mylogger.info("Here4");
			System.err.println("Missing CCXML event parameter!");
			return false;
		}
		
		List<NameValuePair> args = new ArrayList<NameValuePair>();
		
		args.add(new BasicNameValuePair("sessionid", sessionId));
		args.add(new BasicNameValuePair("name", eventName));
		if(eventSource != null && eventSource.length() > 0) {
			args.add(new BasicNameValuePair("eventsource", eventSource));
		}
		
		for(Map.Entry<String, String> pair : parameters.entrySet()) {
			args.add(new BasicNameValuePair(pair.getKey(), pair.getValue()));
		}
		mylogger.info("Here5");
		HttpPost request = new HttpPost(eventUrl);
		//UrlEncodedFormEntity entity = new UrlEncodedFormEntity(args, "UTF-8");
		//request.setEntity(entity);
		try {
			mylogger.info("Here6");
			return eventProcessor.execute(request, eventHandler, eventContext);
		} catch(RuntimeException e)	{
			request.abort();
			throw e;
		}
	}
	
	static void threadMessage(String message) {
        String threadName = Thread.currentThread().getName();
        System.out.format("%s: %s%n", threadName, message);
    }

	/**
	 * @return the mylogger
	 */
	public Logger getMylogger() {
		return mylogger;
	}


	/**
	 * @param mylogger the mylogger to set
	 */
	public void setLogger(Logger mylogger) {
		this.mylogger = mylogger;
	}
	
}
