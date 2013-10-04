<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ccxml PUBLIC "-//W3C//DTD CCXML 1.0//EN" "http://www.w3.org/TR/ccxml/ccxml.dtd">
<ccxml version="1.0" xmlns="http://www.w3.org/2002/09/ccxml">
<%@ page import="java.util.*"%>
<%@ page import="java.net.*"%>
<%@ page contentType="application/ccxml+xml"%>
<%
System.out.println("RadishDemo " + System.currentTimeMillis());
/* do not want jsp content cached */
response.setHeader("Cache-Control", "no-store");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "1");
/* 
 * grab the host and save the app server host port for use later 
 * this makes the application urls "relative" to request so when
 * we deploy this application we do not have to change the urls.
 */
URL url = new URL (request.getRequestURL().toString());
String host = url.getHost();
String port = Integer.toString(url.getPort());

//String host = "192.168.1.185";
//String port = "8443";


String locationExt = "https://" + host + ":" + port;
String locationLocal = locationExt + "/RadishDemo";


%>

<!-- This is the main ccxml file for interacting with Radish Systems Choiceview -->
<!-- This script is for debugging purposes -->

	<script>
	   function objectToString(  obj ) { 
		   var result = " [\n"; 
		   result += extractprops( "", obj); 
		   result += " ]";
		   return result; 
	   } 

	   function extractprops ( parent, obj ) { 
		   var prop, name, result = ""; 
		   var count = 1; 
		   if ( typeof ( obj ) == "object" ) { 
			   for ( prop in obj ) { 
				   name = parent + prop; 
				   if ( typeof ( obj [ prop ] ) == "object" ) { 
					   result += extractprops( name+".", obj [ prop ] );
				   } else { 
					   result +=   " " + name + ":" + obj [ prop ] + "\n"; 
				   } 
				   count = count + 1; 
			   } 
		   } else { 
			   if (obj == undefined ) { 
				   result +=  "___undefined"; 
			   } else { 
				   result +=  obj; 
			   } 
		   } 
		   return result; 
	   } 
   </script>
   
   
	<var name="in_connectionid"/> 	<!-- The connectionid of the incoming call. -->
	<var name="dialogid"/>        	<!-- The id of the dialog we will run. -->
	<var name="callID"/>		  	<!-- The caller's ANI -->
	<var name="sessionID"/>			<!--  The CCXML sessionID -->
	<var name="myURL"/>				<!--  This is the URL that is passed into the ChoiceViewSession object. It specifies where to send control messages back to -->
	<var name="menuName"/>
	<var name="buttonName"/>
	
	<var name="basicHttpURL" expr="'<%=getServletContext().getInitParameter("basicHttpURL")%>'"/>
	
	<var name="pollInterval" expr="'<%=getServletContext().getInitParameter("pollInterval")%>'"/>
	
	<var name="keystoreLocation" expr="'<%=getServletContext().getInitParameter("keystoreLocation")%>'"/>
	<var name="keystorePassword" expr="'<%=getServletContext().getInitParameter("keystorePassword")%>'"/>
	
	<var name="truststoreLocation" expr="'<%=getServletContext().getInitParameter("truststoreLocation")%>'"/>
	<var name="truststorePassword" expr="'<%=getServletContext().getInitParameter("truststorePassword")%>'"/>
	
	<var name="cvHost" expr="'<%=getServletContext().getInitParameter("ChoiceViewHost")%>'"/>
	<var name="cvHostUser" expr="'<%=getServletContext().getInitParameter("ChoiceViewHostUser")%>'"/>
	<var name="cvHostPassword" expr="'<%=getServletContext().getInitParameter("ChoiceViewHostPassword")%>'"/>
	
	
	<!-- Initialize the state for this page -->
	<var name="state" expr="'init'"/>

<!-- Possible states:
	init 	- The initialized state, accept the call.  Since this is the only state
	          you could not use state at all.
	CV		- in a ChoiceView app
	IVR		- running your app
	CVInit 	- In this state, we are setting up the Choice View Session
	CVMain  - The Main Menu Dialog
	LoadHTML
	CVTransfer
	CVRemoteDisconnect
-->

<!-- Event processor -->
  <eventprocessor statevariable="state">
  
  	<!-- STATE: init -->
  
  	<transition event="ccxml.loaded" >
  		<assign name="sessionID" expr="session.id"/>
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        <log expr="'   RadishDemo start.ccxml ccxml.loaded event'"/>
        <log expr="'   RadishDemo sessionID: ' + sessionID + '###'"/>
        <log expr="'   ###session.ioprocessors: ' + session.ioprocessors['basichttp'] + '###'"/>
        <assign name="myURL" expr="session.ioprocessors['basichttp']"/>
        <assign name="sessionID" expr="session.id"/>
		
        <script> 
			//Depending on the environment, it may be easier to set this in the web.xml
			//session.ioprocessors['basichttp'] may not return a value that will work
			//given the security requirements of all the different components.

			//myURL =  basicHttpURL;
		</script>
		
        <log expr="'###myURL: ' + myURL"/>    
	</transition>
	
  
	<!-- Prepare a dialog to load the initial prompt for ChoiceView or not -->
    <transition event="connection.alerting"  state="init">
    	<log expr="'RadishDemo starting'"/>
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        <assign name="in_connectionid" expr="event$.connectionid"/>
        <assign name="callID" expr="session.connections[event$.connectionid].remote"/>
        
        <script> 
          	callID = callID.replace("tel:+1", "");
          	callID = callID.replace("+", "");
          	
          	if(callID.length > 10){
          		callID = callID.substr(1,10);
          	}
        </script>
        
        <log expr="'Preparing Choice' "/>
        
        <dialogprepare 
   			type="'application/voicexml+xml'" 
        	connectionid = "in_connectionid"
        	parameters="callID in_connectionid"
			src="'<%=locationLocal%>/vxml/Choice.vxml'" />	
    </transition>
		
    <!-- Dialog is prepared, accept the call-->			
    <transition event="dialog.prepared"  state="init">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
	    <assign name="dialogid" expr="event$.dialogid"/>
		<accept connectionid="in_connectionid"/>
    </transition>

	<!-- Call is now connected, Start the dialog -->
    <transition event="connection.connected"  state="init">
		<log expr="'***** CALL WAS ANSWERED *****'"/>
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        <dialogstart prepareddialogid="dialogid" connectionid="in_connectionid"/>
     </transition>
 
    <transition event="dialog.started"  state="init">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        
        <!-- 
        Start the CV Session while the prompt is playing.
        The startSession call will block until the caller presses start on their
        mobile device. When they press start, the fetch.done event is thrown for the init state.
        At this point, we need to launch the MainMenu dialog and html page. 
        -->
        <fetch next="'<%=locationLocal%>/jsp/establishCV.jsp'" type="'text/ecmascript'" namelist="callID in_connectionid myURL sessionID pollInterval keystoreLocation keystorePassword truststoreLocation truststorePassword cvHost cvHostUser cvHostPassword"/>
    </transition>

	<!-- Finished playing the Choice dialog, now wait for ChoiceView events or start your non ChoiceView app   -->
    <transition event="dialog.exit"  state="init">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        <var name="outResult" expr = "event$.values.result"/>
        <log expr="'result is ' + outResult"/>
        
        <!-- 
        If we get here, then the caller has not pressed start on their mobile device before the dialog has exited.

        Play the normal IVR menus
        -->        
      <if cond="outResult == 'IVR'" >
        
        	<!--  Launch the Avaya OD application with no Choice View Support -->	  
        	<log expr="'Choice View Menu timed out or 1 was pressed. Will start IVR application.'"/>
        	
        	<log expr="'got standard - want to execute OD App here'"/>
        	<assign name="in_connectionid" expr="event$.connectionid"/>
			<assign name="state" expr="'IVR'"/>
        	
        	<dialogprepare
        	    connectionid = "in_connectionid"        	
   				type="'application/voicexml+xml'" 
				src="<%=locationExt%>/RadishTest/Start'" />
        </if>
    </transition>
    <!--  Prepare the [IVR] dialog  -->
	<transition event="dialog.prepared"  state="IVR">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
	    <assign name="dialogid" expr="event$.dialogid"/>
        <dialogstart prepareddialogid="dialogid" connectionid="in_connectionid"/>
     </transition>    

	<!--  Start the [IVR] dialog  -->
   	<transition event="dialog.started"  state="IVR">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
    </transition>

	<!--  The [IVR] dialog  exited normally-->
    <transition event="dialog.exit"  state="IVR">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        <exit/>        
    </transition>
    
    <!--  The [IVR] dialog  exited normally-->
    <transition event="connection.disconnected"  state="IVR">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        <exit/>        
    </transition>
      
	<!--  
	Right now this isn't being used. We need a way to cancel the startSesion
	Currently, it just times out.
	 --> 
   	<transition event="fetch.done"  state="cancelStartSession">
    	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        
        <!-- Define our return variables -->
        <var name="result" expr="'OKAY'"/>
      
        <!-- execute the returned ECMAScript -->
        <script fetchid="event$.fetchid"/>
        
        <!-- Log the results -->
    	<log expr="'endCV.jsp result:' + result"/>
    	
    	<assign name="state" expr="'IVR'"/>
    	
    	<dialogprepare
        	    connectionid = "in_connectionid"        	
   				type="'application/voicexml+xml'" 
				src="'<%=locationExt%>/RadishTest/Start'" />
	
    </transition>

    <!--  handle any hangups in the [init] state -->
    <transition event="connection.disconnected"  state="init">
     	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
      	<exit/>      
    </transition>
	<!--  
	Choice View Initialization State  
	we get here if the caller presses start on the phone  client.
	That will cause the establishCV.jsp session to throw the fetch.done
	-->
  	<transition event="fetch.done"  state="init">
    	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        
        <!-- Define our return variables -->
        <var name="result" expr="'OKAY'"/>
        <var name="dialogname" expr="''"/>
        
        <!-- execute the returned ECMAScript -->
        <script fetchid="event$.fetchid"/>
        
        <!-- Log the results -->
    	<log expr="'establishCV.jsp result:' + result"/>
    	<log expr="'establishCV.jsp dialogname :' + dialogname"/>
    	
    	<!-- 
    	This gets executed if we couldn't start the CV session for whatever reason
    	we need to terminate the Choice.vxml dialog and just go to the IVR code 
    	-->
    	<if cond="result=='DISCONNECTED'">
    	        
        	<log expr="'Cant start CV session. Will go to IVR app instead.'"/>
        	<assign name="state" expr="'IVR'"/>    
			<dialogprepare
        	    connectionid = "in_connectionid"        	
   				type="'application/voicexml+xml'" 
				src="'<%=locationExt%>/RadishTest/Start'" />
        	
		<else/>
			<log expr="'establishCV.jsp done fetching.'"/>
        	
    	</if>
    	
    </transition>
	<!--  START CHOICE VIEW DIALOG HERE -->
  
    
    <!--  Main Menu Dialog Prepared -->
	<transition event="dialog.prepared"  state="CVMain">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
	    <assign name="dialogid" expr="event$.dialogid"/>
        <dialogstart prepareddialogid="dialogid" connectionid="in_connectionid"/>
     </transition>    

	<!--  Main Menu Dialog Started -->
   	<transition event="dialog.started"  state="CVMain">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
    </transition>

	<!--  Main Menu Dialog completed normally -->
    <transition event="dialog.exit"  state="CVMain">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
    
        <log expr="'   eventdata... \n' + objectToString(event$)"/>  
        
         <var name="dialogSrc" expr="event$.dialog.src"/>
         <var name="isOrderStatus" expr="false"/>
       
        <!-- 
		The Order Status state loops back to the Main menu after a 10 second delay
		The other states have specific handling for Transfer and Disconnect
        -->
         <script>
         	var n=dialogSrc.search("OrderStatus.vxml");
			if(n >=0){
				isOrderStatus = true;
			}
        </script>
        <if cond="isOrderStatus == true">
        	<assign name="state" expr="'LoadHTML'"/> 
        	<assign name="menuName" expr="'Main_Menu'"/> 
        	<assign name="buttonName" expr="''"/>  
	  		<fetch next="locationLocal + '/jsp/loadHTML.jsp'" type="'text/ecmascript'" namelist="callID in_connectionid myURL sessionID menuName buttonName "/>
	  	</if>    
		
	</transition>
    <!-- 
    When the VXML code initiates a transfer, then this event is thrown.
    We must initiate the transfer here when we catch this event
    -->
    <transition event="dialog.transfer"  state="CVMain">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>

 		 <assign name="state" expr="'CVTransfer'"/> 
 		 <createcall dest="event$.uri" connectionid="event$.connectionid"/>
 
    </transition>
    
    <!--  
    Handle a disconnect in the [CVMain] state.
    This is thrown when the caller hangs up from the mobile device
     -->
    <transition event="connection.disconnected"  state="CVMain">
    
     	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        
        <!--  
        We need to end the ChoiceViewSession, so change the state to [CVCleanup] and transition
        to the cleanup handling 
        -->
        <assign name="state" expr="'CVCleanup'"/> 
        <fetch next="'<%=locationLocal%>/jsp/endCV.jsp'" type="'text/ecmascript'"  
            	namelist="callID in_connectionid"/>        
    </transition>
    

    <!--  
    Handle ControlMessages From Choice View Here 
    These messages are send whenever there is any user input from the mobile device
    -->
	<transition event="controlmessage" >
	
	  <log expr="'#####Received Control Message Event#####'" />
	  <log expr="'   eventdata... \n' + objectToString(event$)"/>
	  <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
	  <log expr="'sourcetype=' + event$.eventsourcetype" />
	  <log expr="'eventsource=' + event$.eventsource" />
	  <log expr="'ButtonNumber=' + event$.buttonNumber" />
	  <log expr="'MenuNumber=' + event$.menuNumber" />
	  
	  <assign name="menuName" expr="event$.menuName"/>
	  <assign name="buttonName" expr="event$.buttonName"/>
	  
	  <log expr="'MenuName=' + menuName" />
	  <log expr="'ButtonName=' + buttonName" />
	  
	  <!--  Immediately terminate the current dialog when a button is tapped on the mobile device -->
	  <dialogterminate dialogid="dialogid" immediate="true"/>
	  
	  <!-- 
	  Pass the button/menu info to the jsp. It will determine the right dialog 
	  to play next and load the next html page to the mobile device based on the controlmessage info 
	  -->
	  <assign name="state" expr="'LoadHTML'"/>  
	  <fetch next="'<%=locationLocal%>/jsp/loadHTML.jsp'" type="'text/ecmascript'" namelist="callID in_connectionid menuName buttonName"/>
	  
	</transition>
	
	<!-- 
	This message is send when the user ends the session on the mobile device.
	We need to terminate the current dialog and then clean up the session.
	 -->
	<transition event="statechange">
		<log expr="'#####Received State Change Event#####'" />
	  	<log expr="'   eventdata... \n' + objectToString(event$)"/>
		<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
		<log expr="'newstate=' + event$.newstate" />
		
		<!-- 
		Handle the disconnect. Terminate the voice dialog and then transition 
		to a state where we play the caller a goodbye message 
		-->
		<if cond="'disconnected' == event$.newstate">
			<if cond="state=='CVTransfer'">
			<else/>
				<dialogterminate dialogid="dialogid" immediate="true"/>
				<assign name="state" expr="'CVRemoteDisconnect'"/> 
			</if>
		</if>
		
		<!--  The caller pressed start, so now we need to load the main menu -->
		<if cond="'connected' == event$.newstate">
			<dialogterminate dialogid="dialogid" immediate="true"/>
    		  
    		<!-- prepare the dialog. This should be the MainMenu-->
    		<assign name="state" expr="'CVMain'"/>
    		<log expr="'Preparing Main Menu dialog in statechange'"/>
    		
    		<assign name="state" expr="'LoadHTML'"/> 
        	<assign name="menuName" expr="'Main_Menu'"/> 
        	<assign name="buttonName" expr="''"/>  
	  		<fetch next="'<%=locationLocal%>/jsp/loadHTML.jsp'" type="'text/ecmascript'" namelist="callID in_connectionid myURL sessionID menuName buttonName "/>
    	
		</if>
	</transition>
	
	<transition event="error.semantic" state="CVMain">
    	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>  
		<log expr="'   eventdata... \n'"/>  
      </transition>
	<!-- 
	When we terminate the dialog, it is going to throw a dialog.exit.
	We catch it here and then transition to the Goodbye state 
	-->
	<transition event="dialog.exit"  state="CVRemoteDisconnect">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>  
        <assign name="state" expr="'CVGoodbye'"/> 
        
        <!--  Prepare the Goodbye dialog -->
         <dialogprepare 
	   			type="'application/voicexml+xml'" 
	        	connectionid = "in_connectionid"
  
	        	parameters="callID in_connectionid"
				src="'<%=locationLocal%>/vxml/Goodbye.vxml'" />    
    </transition>
	
    <transition event="error.semantic" state="CVRemoteDisconnect">
    	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>  
        <assign name="state" expr="'CVGoodbye'"/> 
        
        <!--  Prepare the Goodbye dialog -->
         <dialogprepare 
	   			type="'application/voicexml+xml'" 
	        	connectionid = "in_connectionid"
	        	parameters="callID in_connectionid"
				src="locationLocal + '/vxml/Goodbye.vxml'" />   
    </transition>
    
    <!-- 
    We would have transitioned to the [Cleanup] state somewhere above if 
    we trapped a hangup or disconnect. Of we are done cleanup up, then we just exit. 
    -->
	<transition event="fetch.done"  state="CVCleanup">
    	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        
        <!-- Define our return variables -->
        <var name="result" expr="'OKAY'"/>
      
        <!-- execute the returned ECMAScript -->
        <script fetchid="event$.fetchid"/>
        
        <!-- Log the results -->
    	<log expr="'endCV.jsp result:' + result"/>
    	<exit/>
	
    </transition>
    
    <!--  The [CVCleanup] State exited normally -->
    <transition event="dialog.exit"  state="CVCleanup">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>       
    </transition>
	
	<!--  
	This is a generic handler for the [LoadHTML] state. 
	This state is used for all of the different menu options.
	We either loop back to the main menu or we go to the goodbye state.  
	-->
	<!--  The [LoadHTML] dialog prepared -->
    <transition event="dialog.prepared"  state="LoadHTML">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>      
    </transition>
    
	<!--  The [LoadHTML] dialog fetch.done -->
  	<transition event="fetch.done"  state="LoadHTML">
    	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
       
        
        <!-- Define our return variables -->
        <var name="result" expr="'OKAY'"/>
        <var name="dialogname" expr="''"/>
        
        <!-- execute the returned ECMAScript -->
        <script fetchid="event$.fetchid"/>
        
        <!-- Log the results -->
    	<log expr="'loadHTML.jsp result:' + result"/>
    	<log expr="'loadHTML.jsp dialogname :' + dialogname"/>
    	
    	<!--  if this is the radish website page, we want to disconnect -->
    	<if cond="'DISCONNECT' == result">
    		<assign name="state" expr="'CVGoodbye'"/>
    	<elseif cond="'TRANSFER' == result"/>
    		<assign name="state" expr="'CVTransfer'"/> 
    	<else/>
    		<assign name="state" expr="'CVMain'"/> 
    	</if>
    	 
    	<!-- prepare the dialog -->
        <dialogprepare connectionid = "in_connectionid" 
			type="'application/voicexml+xml'" 
			src="'<%=locationLocal%>/vxml/' + dialogname" />		
    </transition>
    
    <!--  The [LoadHTML] state exited normally -->
     <transition event="dialog.exit"  state="LoadHTML">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>      
    </transition>
    
    
    <!--  GOODBYE DIALOG -->
    
    <!-- The [CVGoodbye] state was prepared -->
    <transition event="dialog.prepared"  state="CVGoodbye">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
	    <assign name="dialogid" expr="event$.dialogid"/>
         <dialogstart prepareddialogid="dialogid" connectionid="in_connectionid"/>
     </transition>    


	<!-- The [CVGoodbye] state was started -->
   	<transition event="dialog.started"  state="CVGoodbye">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
    </transition>
    
    <!-- The [CVGoodbye] state exited normally -->
     <transition event="dialog.exit"  state="CVGoodbye">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>  
        
        <!--  Now transition to [Cleanup] to end the CV Session -->
		<assign name="state" expr="'CVCleanup'"/> 
		<fetch next="'<%=locationLocal%>/jsp/endCV.jsp'" type="'text/ecmascript'"  namelist="callID in_connectionid"/>  	
       
    </transition>
    
    <!-- If the caller Hangs up in the Goodbye dialog, handle it here -->
    <transition event="connection.disconnected"  state="CVGoobye">
    
     	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        <assign name="state" expr="'CVCleanup'"/> 
        <fetch next="'<%=locationLocal%>/jsp/endCV.jsp'" type="'text/ecmascript'"  
            	namelist="callID in_connectionid"/>        
    </transition>
    
    
    <!--  TRANSFER  -->
    
	<transition event="dialog.prepared"  state="CVTransfer">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
	    <assign name="dialogid" expr="event$.dialogid"/>
         <dialogstart prepareddialogid="dialogid" connectionid="in_connectionid"/>
     </transition>    


	<!-- The [CVTransfer] state was started -->
   	<transition event="dialog.started"  state="CVTransfer">
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
    </transition>
    
    <transition event="connection.alerting"  state="CVTransfer">
    	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
                
	</transition>
	
	 <transition event="connection.disconnected"  state="CVTransfer">
    
     	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
        <assign name="state" expr="'CVCleanup'"/> 
        <fetch next="locationLocal + '/jsp/endCV.jsp'" type="'text/ecmascript'"  
            	namelist="callID in_connectionid"/>        
    </transition>
    <!-- When we call <createcall> in the [CVMain] state, this event is thrown, so handle it here-->
    <transition event="connection.progressing"  state="CVTransfer">
    
     	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
                
	</transition>
    
    <!-- This is thrown when the Transfer is connected -->
  	<transition event="connection.connected"  state="CVTransfer">
    
     	<log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
               
        <!--  Don't forget to cleanup --> 
        <assign name="state" expr="'CVCleanup'"/> 
        <fetch next="'<%=locationLocal%>/jsp/endCV.jsp'" type="'text/ecmascript'"  	namelist="callID in_connectionid"/>
    </transition>

	<!-- STATE: ANYSTATE. Catch all, aids in debugging and to see the missed events -->
	
	<transition event="error.dialog.notprepared" >
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
		<reject connectionid="in_connectionid"/>
    </transition>

    <transition event="error.dialog.notstarted" >
 		<log expr="'****** ERROR.DIALOGNOTSTARTED.NAME = ' + event$.name +' -- [' + state +']'"/>
      	<log expr="'***** EVENT$.NAME  = ' + event$.name"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
		<disconnect connectionid="in_connectionid" reason="event$.reason" />
    </transition>
    
    
	<transition event="ccxml.exit" >
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
	</transition>

	<transition event="ccxml.kill" >
        <log expr="'-- ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
	</transition>

    <transition event="" >
        <log expr="'-- missed ' + event$.name +' -- [' + state +']'"/>
        <log expr="'   eventdata... \n' + objectToString(event$)"/>
    </transition>
    
    <transition event="error.*">
	<log expr="'-- missed ' + event$.name +' -- [' + state +']'"/>
      <log expr="'an error has occured (' + event$.reason + ')'"/>
       <log expr="'   eventdata... \n' + objectToString(event$)"/>

      <exit/>
    </transition>



  </eventprocessor>
</ccxml>