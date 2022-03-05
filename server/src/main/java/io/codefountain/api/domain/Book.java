package io.codefountain.api.domain;

import lombok.Data;

import javax.persistence.Entity;
import javax.persistence.Id;

@Data
@Entity
public class Book {

    @Id
    private long bookId;
    private String bookTitle;
    private String bookAuthor;
    private String bookPublisher;

}