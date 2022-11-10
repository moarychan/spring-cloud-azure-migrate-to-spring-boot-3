package com.example.azure.spring.controller;

import com.example.azure.spring.entity.DemoEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Sinks;

@RestController
@RequestMapping("message")
public class MessageController {

  private static final Logger LOGGER = LoggerFactory.getLogger(MessageController.class);

  private final Sinks.Many<Message<DemoEvent>> sinkMany;


  public MessageController(Sinks.Many<Message<DemoEvent>> sinkMany) {
    this.sinkMany = sinkMany;
  }

  @PostMapping("/send")
  public String send(@RequestBody DemoEvent demoEvent) {
    LOGGER.info("Start to send message: {}", demoEvent);
    sinkMany.emitNext(MessageBuilder.withPayload(demoEvent).build(), Sinks.EmitFailureHandler.FAIL_FAST);
    return "Message has sent";
  }
}
