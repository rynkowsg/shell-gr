#!/usr/bin/env bash
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

dict_equal() {
  local -n arr1=$1
  local -n arr2=$2

  # Check if the number of keys in both arrays are the same
  if [ "${#arr1[@]}" -ne "${#arr2[@]}" ]; then
    echo "Arrays are not equal (different lengths)"
    return 1
  fi

  # Check if all keys and values in arr1 exist in arr2
  for key in "${!arr1[@]}"; do
    if [[ ! -v arr2[$key] ]] || [[ "${arr1[$key]}" != "${arr2[$key]}" ]]; then
      echo "Arrays are not equal (difference found at key: $key)"
      return 1
    fi
  done

  # Check if all keys and values in arr2 exist in arr1
  for key in "${!arr2[@]}"; do
    if [[ ! -v arr1[$key] ]] || [[ "${arr2[$key]}" != "${arr1[$key]}" ]]; then
      echo "Arrays are not equal (difference found at key: $key)"
      return 1
    fi
  done

  echo "Arrays are equal"
  return 0
}

# $1 = source varname (contains associative array to be serialized)
# $2 = target varname (will contain the serialized string)
serialize_dict() {
  local -n dict=$1
  local -n serialized_str=$2
  local entry_delimiter=$'\x01'     # Start of Heading as entry delimiter
  local key_value_delimiter=$'\x1E' # Record Separator as key-value delimiter
  for key in "${!dict[@]}"; do
    serialized_str+="${key}${key_value_delimiter}${dict[${key}]}${entry_delimiter}"
  done
  # Remove the trailing delimiter
  serialized_str="${serialized_str%"${entry_delimiter}"}"
}

# $1 = source varname (contains the serialized string)
# $2 = target varname (will contain associative array deserialized from string)
deserialize_to_dict() {
  local -n serialized=$1
  local -n dict=$2
  local entry_delimiter=$'\x01'     # Start of Heading as entry delimiter
  local key_value_delimiter=$'\x1E' # Record Separator as key-value delimiter
  IFS="$entry_delimiter" read -ra entries <<<"${serialized}"
  for entry in "${entries[@]}"; do
    # Split each entry into key and value based on the key-value delimiter
    IFS="${key_value_delimiter}" read -r key value <<<"${entry}"
    dict["${key}"]="${value}"
  done
}
