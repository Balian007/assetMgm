package com.company.asset.common.result;

import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

@Data
@EqualsAndHashCode(callSuper = true)
public class PageResult<T> extends Result<PageResult.PageData<T>> {

    public static <T> Result<PageData<T>> page(List<T> records, long total) {
        PageData<T> data = new PageData<>();
        data.records = records;
        data.total = total;
        return Result.ok(data);
    }

    @Data
    public static class PageData<T> {
        private List<T> records;
        private long total;
    }
}
