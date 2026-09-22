//! Smallest possible crate used to self-test rust-ci.yml.

/// Returns `a + b`.
pub fn sum(a: i64, b: i64) -> i64 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn adds_two_numbers() {
        assert_eq!(sum(2, 3), 5);
    }
}
