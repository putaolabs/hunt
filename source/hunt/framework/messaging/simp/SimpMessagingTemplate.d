/*
 * Copyright 2002-2018 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module hunt.framework.messaging.simp;

import hunt.container.Map;


import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageChannel;
import hunt.framework.messaging.MessageDeliveryException;
import hunt.framework.messaging.MessageHeaders;
import hunt.framework.messaging.MessagingException;
import hunt.framework.messaging.core.AbstractMessageSendingTemplate;
import hunt.framework.messaging.core.MessagePostProcessor;
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;
import hunt.framework.messaging.support.MessageHeaderInitializer;
import hunt.framework.messaging.support.NativeMessageHeaderAccessor;
import org.springframework.util.Assert;
import org.springframework.util.StringUtils;

/**
 * An implementation of
 * {@link hunt.framework.messaging.simp.SimpMessageSendingOperations}.
 *
 * <p>Also provides methods for sending messages to a user. See
 * {@link hunt.framework.messaging.simp.user.UserDestinationResolver
 * UserDestinationResolver}
 * for more on user destinations.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
public class SimpMessagingTemplate extends AbstractMessageSendingTemplate!(string)
		implements SimpMessageSendingOperations {

	private final MessageChannel messageChannel;

	private string destinationPrefix = "/user/";

	private long sendTimeout = -1;

	
	private MessageHeaderInitializer headerInitializer;


	/**
	 * Create a new {@link SimpMessagingTemplate} instance.
	 * @param messageChannel the message channel (never {@code null})
	 */
	public SimpMessagingTemplate(MessageChannel messageChannel) {
		Assert.notNull(messageChannel, "MessageChannel must not be null");
		this.messageChannel = messageChannel;
	}


	/**
	 * Return the configured message channel.
	 */
	public MessageChannel getMessageChannel() {
		return this.messageChannel;
	}

	/**
	 * Configure the prefix to use for destinations targeting a specific user.
	 * <p>The default value is "/user/".
	 * @see hunt.framework.messaging.simp.user.UserDestinationMessageHandler
	 */
	public void setUserDestinationPrefix(string prefix) {
		Assert.hasText(prefix, "User destination prefix must not be empty");
		this.destinationPrefix = (prefix.endsWith("/") ? prefix : prefix ~ "/");

	}

	/**
	 * Return the configured user destination prefix.
	 */
	public string getUserDestinationPrefix() {
		return this.destinationPrefix;
	}

	/**
	 * Specify the timeout value to use for send operations (in milliseconds).
	 */
	public void setSendTimeout(long sendTimeout) {
		this.sendTimeout = sendTimeout;
	}

	/**
	 * Return the configured send timeout (in milliseconds).
	 */
	public long getSendTimeout() {
		return this.sendTimeout;
	}

	/**
	 * Configure a {@link MessageHeaderInitializer} to apply to the headers of all
	 * messages created through the {@code SimpMessagingTemplate}.
	 * <p>By default, this property is not set.
	 */
	public void setHeaderInitializer(MessageHeaderInitializer headerInitializer) {
		this.headerInitializer = headerInitializer;
	}

	/**
	 * Return the configured header initializer.
	 */
	
	public MessageHeaderInitializer getHeaderInitializer() {
		return this.headerInitializer;
	}


	/**
	 * If the headers of the given message already contain a
	 * {@link hunt.framework.messaging.simp.SimpMessageHeaderAccessor#DESTINATION_HEADER
	 * SimpMessageHeaderAccessor#DESTINATION_HEADER} then the message is sent without
	 * further changes.
	 * <p>If a destination header is not already present ,the message is sent
	 * to the configured {@link #setDefaultDestination(Object) defaultDestination}
	 * or an exception an {@code IllegalStateException} is raised if that isn't
	 * configured.
	 * @param message the message to send (never {@code null})
	 */
	override
	public void send(Message<?> message) {
		Assert.notNull(message, "Message is required");
		string destination = SimpMessageHeaderAccessor.getDestination(message.getHeaders());
		if (destination !is null) {
			sendInternal(message);
			return;
		}
		doSend(getRequiredDefaultDestination(), message);
	}

	override
	protected void doSend(string destination, Message<?> message) {
		Assert.notNull(destination, "Destination must not be null");

		SimpMessageHeaderAccessor simpAccessor =
				MessageHeaderAccessor.getAccessor(message, SimpMessageHeaderAccessor.class);

		if (simpAccessor !is null) {
			if (simpAccessor.isMutable()) {
				simpAccessor.setDestination(destination);
				simpAccessor.setMessageTypeIfNotSet(SimpMessageType.MESSAGE);
				simpAccessor.setImmutable();
				sendInternal(message);
				return;
			}
			else {
				// Try and keep the original accessor type
				simpAccessor = (SimpMessageHeaderAccessor) MessageHeaderAccessor.getMutableAccessor(message);
				initHeaders(simpAccessor);
			}
		}
		else {
			simpAccessor = SimpMessageHeaderAccessor.wrap(message);
			initHeaders(simpAccessor);
		}

		simpAccessor.setDestination(destination);
		simpAccessor.setMessageTypeIfNotSet(SimpMessageType.MESSAGE);
		message = MessageBuilder.createMessage(message.getPayload(), simpAccessor.getMessageHeaders());
		sendInternal(message);
	}

	private void sendInternal(Message<?> message) {
		string destination = SimpMessageHeaderAccessor.getDestination(message.getHeaders());
		Assert.notNull(destination, "Destination header required");

		long timeout = this.sendTimeout;
		 sent = (timeout >= 0 ? this.messageChannel.send(message, timeout) : this.messageChannel.send(message));

		if (!sent) {
			throw new MessageDeliveryException(message,
					"Failed to send message to destination '" ~ destination ~ "' within timeout: " ~ timeout);
		}
	}

	private void initHeaders(SimpMessageHeaderAccessor simpAccessor) {
		if (getHeaderInitializer() !is null) {
			getHeaderInitializer().initHeaders(simpAccessor);
		}
	}


	override
	public void convertAndSendToUser(string user, string destination, Object payload) throws MessagingException {
		convertAndSendToUser(user, destination, payload, (MessagePostProcessor) null);
	}

	override
	public void convertAndSendToUser(string user, string destination, Object payload,
			Map!(string, Object) headers) throws MessagingException {

		convertAndSendToUser(user, destination, payload, headers, null);
	}

	override
	public void convertAndSendToUser(string user, string destination, Object payload,
			MessagePostProcessor postProcessor) throws MessagingException {

		convertAndSendToUser(user, destination, payload, null, postProcessor);
	}

	override
	public void convertAndSendToUser(string user, string destination, Object payload,
			Map!(string, Object) headers, MessagePostProcessor postProcessor)
			throws MessagingException {

		Assert.notNull(user, "User must not be null");
		user = StringUtils.replace(user, "/", "%2F");
		destination = destination.startsWith("/") ? destination : "/" ~ destination;
		super.convertAndSend(this.destinationPrefix + user + destination, payload, headers, postProcessor);
	}


	/**
	 * Creates a new map and puts the given headers under the key
	 * {@link NativeMessageHeaderAccessor#NATIVE_HEADERS NATIVE_HEADERS NATIVE_HEADERS NATIVE_HEADERS}.
	 * effectively treats the input header map as headers to be sent out to the
	 * destination.
	 * <p>However if the given headers already contain the key
	 * {@code NATIVE_HEADERS NATIVE_HEADERS} then the same headers instance is
	 * returned without changes.
	 * <p>Also if the given headers were prepared and obtained with
	 * {@link SimpMessageHeaderAccessor#getMessageHeaders()} then the same headers
	 * instance is also returned without changes.
	 */
	override
	protected Map!(string, Object) processHeadersToSend(Map!(string, Object) headers) {
		if (headers is null) {
			SimpMessageHeaderAccessor headerAccessor = SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);
			initHeaders(headerAccessor);
			headerAccessor.setLeaveMutable(true);
			return headerAccessor.getMessageHeaders();
		}
		if (headers.containsKey(NativeMessageHeaderAccessor.NATIVE_HEADERS)) {
			return headers;
		}
		if (headers instanceof MessageHeaders) {
			SimpMessageHeaderAccessor accessor =
					MessageHeaderAccessor.getAccessor((MessageHeaders) headers, SimpMessageHeaderAccessor.class);
			if (accessor !is null) {
				return headers;
			}
		}

		SimpMessageHeaderAccessor headerAccessor = SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);
		initHeaders(headerAccessor);
		headers.forEach((key, value) -> headerAccessor.setNativeHeader(key, (value !is null ? value.toString() : null)));
		return headerAccessor.getMessageHeaders();
	}

}