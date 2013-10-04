/**
 * Date: 		August 12, 2013
 * File Name: 	ChoiceViewServlet.java
 * Project Name: ChoiceView
 */
package com.radish.choiceview;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.ServletConfig;
import java.util.concurrent.*;
import java.util.*;
import org.apache.log4j.*;

import com.radishsystems.choiceview.webapi.*;

import java.io.*;
import java.text.*;

/**
 * @author Derek Teuscher
 */
public class ChoiceViewServlet extends HttpServlet {

	/* Instantiate a logger named ServletLogger */
	private static Logger mylogger = null;

	private static Properties logProperties = null;
	private static ServletConfig cfg = null;

	private static boolean loggedMessage = false;
	
	private static Map <String, Thread>cvThreads;
	
	/**
	 *
	 */
	public ChoiceViewServlet() {
	}

	/* (non-Javadoc)
	 * @see javax.servlet.GenericServlet#init()
	 */
	@Override
	public void init() throws ServletException {

		super.init();

		cfg = getServletConfig();
		if(cfg == null){
			System.out.println("*** The ServletConfig is null");
		}

		initLogger();
		
		cvThreads = new HashMap();
	
		mylogger.debug("Starting ChoiceView Servlet");
		
	}
	
	public static boolean addSession(String sessionID, ChoiceViewSession cvs, String sessionURL,  String basicHttpID, long pollInterval){
		
		if(cvThreads.containsKey(sessionID)){
			
			mylogger.warn("Session " + sessionID + " already exists");
			
			return false;
			
		}else{
			ChoiceViewPollingThread checker = new ChoiceViewPollingThread(sessionID, cvs, sessionURL, basicHttpID, pollInterval);
			checker.setLogger(mylogger);
			Thread t = new Thread(checker);
			t.start();
			
			cvThreads.put(sessionID, t);
			
			mylogger.debug("Started new ChoiceView Polling Thread; SessionID: " + sessionID + ". ThreadID: " + t.getId());
		}
		
		return true;
	}

	public static boolean removeSession(String sessionID){
		
		if(cvThreads.containsKey(sessionID)){
			
			Thread cvThread  = cvThreads.get(sessionID);
			
			mylogger.debug("Stopping ChoiceView Polling Thread; SessionID: " + sessionID + ". ThreadID: " + cvThread.getId());
			
			while(cvThread != null && cvThread.isAlive()){
				cvThread.interrupt();
	             try{
	            	 cvThread.join();
	             }catch(InterruptedException ie){
	            	 mylogger.debug("shut down thread: " + cvThread.getId());
	             }
			}
			
			mylogger.debug("ChoiceView Polling Thread Stopped; SessionID: " + sessionID + ". ThreadID: " + cvThread.getId());
			
			cvThreads.remove(sessionID);
			
		}else{
			mylogger.warn("Session " + sessionID + " does not exist. Can't remove session.");
			
			return false;
		}
		
		return true;
	}

    /**
     * Initialize the log 4j stuff
     */
     private static void initLogger(){

           logProperties = new Properties();

           try{

                 String ddHome;
                 if(cfg != null){
                       ddHome = cfg.getInitParameter("DDAppHome");
                 }else{
                       System.out.println("*** The ServletConfig is null. Using default for DDAppHome.");
                       ddHome = "/usr/share/tomcat6/webapps/RadishDemo";
                 }

                 String log4jFile = ddHome + "/data/ddlog4j.properties";

                 File logDir = new File( ddHome + "/data/log");
                 if(logDir.exists() == false){
                       logDir.mkdir();
                 }

                 logProperties.load(new FileInputStream(log4jFile));
                 logProperties.setProperty("dd.apphome", ddHome);

                 PropertyConfigurator.configure(logProperties);

                 mylogger = Logger.getLogger("Servlet");
                        
                 mylogger.debug("Initialized ChoiceViewServlet logger.");

           }catch(Exception e){
                 BasicConfigurator.configure();
                 mylogger = Logger.getRootLogger();
                 mylogger.error("Couldn't load the log4j properties. Using StdOut.", e);
           }
     }

	/* (non-Javadoc)
	 * @see javax.servlet.GenericServlet#destroy()
	 */
	@Override
	public void destroy() {
		
		mylogger.debug("Stopping ChoiceViewServlet servlet");
		
		//if Tomcat shuts down, we need to stop all of our threads if any;
		Set keys = cvThreads.keySet();
		for(Iterator it =keys.iterator(); it.hasNext();){
			String key = (String) it.next();
			
			Thread t = (Thread) cvThreads.get(key);
			while (t.isAlive()) {
				 t.interrupt();
	             try{
	            	 t.join();
	             }catch(InterruptedException ie){
	            	 mylogger.debug("shut down thread: " + t.getId());
	             }
			}
			
			//now that all of the treads have stopped, then remove them from the map.
			cvThreads.remove(key);
		}

		super.destroy();

	}
	


	/**
	 * @param args
	 */
	public static void main(String[] args) {

		ChoiceViewServlet servlet = new ChoiceViewServlet();

		try{
			servlet.init();

		}catch(Exception e){
			e.printStackTrace();
		}finally{
			servlet.destroy();
		}

	}
}
