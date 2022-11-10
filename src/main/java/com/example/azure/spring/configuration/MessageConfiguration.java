package com.example.azure.spring.configuration;

import com.azure.spring.messaging.AzureHeaders;
import com.azure.spring.messaging.checkpoint.Checkpointer;
import com.example.azure.spring.entity.DemoEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

import java.time.Duration;
import java.util.function.Consumer;
import java.util.function.Supplier;

@Configuration
public class MessageConfiguration {

  private static final Logger LOGGER = LoggerFactory.getLogger(MessageConfiguration.class);

  @Bean
  Sinks.Many<Message<DemoEvent>> sinkMany() {
    return Sinks.many().multicast().onBackpressureBuffer();
  }

  @Bean
  Supplier<Flux<Message<DemoEvent>>> supply(Sinks.Many<Message<DemoEvent>> many) {
    return () -> many.asFlux()
                     .doOnNext(msg -> LOGGER.info("Sending message: {}", msg))
                     .doOnError(ex -> LOGGER.error("Sending message exception", ex));
  }

  @Bean
  Consumer<Message<DemoEvent>> consume() {
    return message -> {
      Checkpointer checkpointer = (Checkpointer) message.getHeaders().get(AzureHeaders.CHECKPOINTER);
      checkpointer.success()
                  .doOnSuccess(pa -> LOGGER.info("Message '{}' successfully checked.", message.getPayload()))
                  .doOnError(ex -> LOGGER.error("Exception found", ex))
                  .block(Duration.ofSeconds(10));
    };
  }
}
